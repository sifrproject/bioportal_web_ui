
/*
ajax-chosen
A complement to the jQuery library Chosen that adds ajax autocomplete
Contributors:
https://github.com/jobvite/ajax-chosen
https://github.com/bicouy0/ajax-chosen
*/

(function() {

  (function($) {
    return $.fn.ajaxChosen = function(options, callback) {
      var clickSelector, container, defaultedOptions, field, inputSelector, multiple, search, select, currentSearchId,
        _this = this;
      defaultedOptions = {
        minLength: 3,
        queryLimit: 10,
        delay: 100,
        chosenOptions: {},
        searchingText: "Searching...",
        noresultsText: "No results.",
        initialQuery: false
      };
      $.extend(defaultedOptions, options);
      defaultedOptions.chosenOptions.no_results_text = defaultedOptions.searchingText;
      select = this;
      multiple = select.attr('multiple') != null;
      if (multiple) {
        inputSelector = ".search-field > input";
        clickSelector = ".chzn-choices";
      } else {
        inputSelector = ".chzn-search > input";
        clickSelector = ".chzn-single";
      }
      select.chosen(defaultedOptions.chosenOptions);
      select.data('chosen').winnow_results = function(){};
      container = select.next('.chzn-container');
      field = container.find(inputSelector);
      if (defaultedOptions.initialQuery) {
        field.bind('focus', function(evt) {
          if (this.previousSearch || !container.hasClass('chzn-container-active')) {
            return;
          }
          return search(evt);
        });
      }
      field.bind('keyup', function(evt) {
        if (this.previousSearch) clearTimeout(this.previousSearch);
        return this.previousSearch = setTimeout((function() {
          return search(evt);
        }), defaultedOptions.delay);
      });
      return search = function(evt) {
        var clearSearchingLabel, currentOptions, prevVal, response, val, _ref, thisSearchId;
        val = $.trim(field.attr('value'));
        prevVal = (_ref = field.data('prevVal')) != null ? _ref : false;
        field.data('prevVal', val);
        thisSearchId = new Date().getTime() + val;
        currentSearchId = thisSearchId;
        var resultsDiv;
        if (multiple) {
          resultsDiv = field.parent().parent().siblings();
        } else {
          resultsDiv = field.parent().parent();
        }
        clearSearchingLabel = function(val) {
          if (typeof val === "undefined" || val === null || val === "") val = $(_this).attr('value');
          return resultsDiv.find('.no-results').html(defaultedOptions.noresultsText + " '" + val + "'");
        };
        if (val === prevVal || (val.length < defaultedOptions.minLength && evt.type === 'keyup')) {
          clearSearchingLabel(val);
          return false;
        }
        if (resultsDiv.find(".no-results").length < 1) {
          resultsDiv.find(".no-results").remove();
          resultsDiv.find(".chzn-results").prepend($("<li/>").addClass("no-results"));
        }
        resultsDiv.find(".active-result").remove();
        resultsDiv.find('.no-results').addClass("searching").html(defaultedOptions.searchingText + " '" + val + "'");
        currentOptions = select.find('option');
        defaultedOptions.term = val;
        response = function(items, success) {
          var currentOpt, keydownEvent, latestVal, newOpt, newOptions, noResult, _fn, _fn2, _i, _j, _len, _len2;
          if (!field.is(':focus') && evt.type === 'keyup') return;
          if (thisSearchId !== currentSearchId) return;
          newOptions = [];
          $.each(items, function(value, text) {
            var newOpt;
            newOpt = $('<option>');
            newOpt.attr('value', value).html(text);
            return newOptions.push($(newOpt));
          });
          _fn = function(currentOpt) {
            var $currentOpt, newOption, presenceInNewOptions;
            $currentOpt = $(currentOpt);
            if ($currentOpt.attr('selected') && multiple) return;
            if ($currentOpt.attr('value') === '' && $currentOpt.html() === '' && !multiple) {
              return;
            }
            presenceInNewOptions = (function() {
              var _j, _len2, _results;
              _results = [];
              for (_j = 0, _len2 = newOptions.length; _j < _len2; _j++) {
                newOption = newOptions[_j];
                if (newOption.attr('value') === $currentOpt.attr('value')) {
                  _results.push(newOption);
                }
              }
              return _results;
            })();
            if (presenceInNewOptions.length === 0) return $currentOpt.remove();
          };
          for (_i = 0, _len = currentOptions.length; _i < _len; _i++) {
            currentOpt = currentOptions[_i];
            _fn(currentOpt);
          }
          select.html(select.find("option:selected"));
          currentOptions = select.find('option');
          _fn2 = function(newOpt) {
            var currentOption, presenceInCurrentOptions, _fn3, _k, _len3;
            presenceInCurrentOptions = false;
            _fn3 = function(currentOption) {
              if ($(currentOption).attr('value') === newOpt.attr('value')) {
                return presenceInCurrentOptions = true;
              }
            };
            for (_k = 0, _len3 = currentOptions.length; _k < _len3; _k++) {
              currentOption = currentOptions[_k];
              _fn3(currentOption);
            }
            if (!presenceInCurrentOptions) return select.append(newOpt);
          };
          for (_j = 0, _len2 = newOptions.length; _j < _len2; _j++) {
            newOpt = newOptions[_j];
            _fn2(newOpt);
          }
          latestVal = field.val();
          if ($.isEmptyObject(items)) {
            noResult = $('<option>');
            noResult.addClass('no-results');
            noResult.html(defaultedOptions.noresultsText + " '" + latestVal + "'").attr('value', '');
            select.find('.no-results').remove();
            select.append(noResult);
          } else {
            select.change();
          }
          select.trigger("liszt:updated");
          $('.no-results').removeClass('active-result');
          field.val(latestVal);
          field.trigger($.Event("keydown"))
          if (!$.isEmptyObject(items)) {
            keydownEvent = $.Event('keydown');
            keydownEvent.which = 40;
            field.trigger(keydownEvent);
          }
          if (success) return success(items);
        };
        return callback(defaultedOptions, response, evt);
      };
    };
  })(jQuery);

}).call(this);
