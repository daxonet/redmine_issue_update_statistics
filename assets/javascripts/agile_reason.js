(function () {
  'use strict';

  document.addEventListener('DOMContentLoaded', function () {
    var config = window.redmineIssueStatisticsAgileReason;
    var $ = window.jQuery;
    if (!$ || !config || !config.fields.length) return;

    // ajaxSend runs after Agile has registered its error/complete callbacks.
    // Aborting here therefore also restores the card and unlocks the board.
    $(document).off('ajaxSend.issueStatisticsReason').on('ajaxSend.issueStatisticsReason', function (_event, xhr, options) {
      var url = new URL(options.url, window.location.href);
      if (url.origin !== window.location.origin || !url.pathname.endsWith('/agile/board') ||
          String(options.type).toUpperCase() !== 'PUT' || typeof options.data !== 'string') return;

      var data = new URLSearchParams(options.data);
      var needsReason = config.fields.some(function (field) {
        var key = field.indexOf('custom_field_') === 0 ?
          'issue[custom_field_values][' + field.slice(13) + ']' : 'issue[' + field + ']';
        if (!data.has(key)) return false;
        if (field === 'status_id') {
          var card = document.querySelector('.issue-card[data-id="' + CSS.escape(data.get('id') || '') + '"]');
          if (card && card.hasAttribute('oldColumnId') && card.getAttribute('oldColumnId') === data.get(key)) return false;
        }
        return true;
      });
      if (!needsReason || (data.get('reason') || data.get('issue[reason]') || '').trim()) return;

      var reason = window.prompt(config.prompt, '');
      if (reason === null || !reason.trim()) {
        xhr.responseText = JSON.stringify([config.required]);
        xhr.abort('canceled');
        return;
      }
      data.set('reason', reason.trim());
      options.data = data.toString();
    });
  });
}());
