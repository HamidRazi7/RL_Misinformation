/**
 * jspsych-misinformation-comments
 * 
 * Plugin for collecting participant feedback in the misinformation task paradigm
 * Implements standardized qualitative data collection interface
 **/

jsPsych.plugins['misinformation-comments'] = (function() {
  var plugin = {};

  plugin.info = {
    name: 'misinformation-comments',
    description: 'Collects qualitative feedback from participants regarding experimental procedures and experiences',
    parameters: {
      button_label: {
        type: jsPsych.plugins.parameterType.STRING,
        pretty_name: 'Button label',
        default: 'Send',
        description: 'Label of the submission button for participant response collection'
      }
    }
  }

  plugin.trial = function(display_element, trial) {
    // Plugin identification configuration
    var plugin_id_name = "jspsych-survey-comments-send";
    var plugin_id_selector = '#' + plugin_id_name;
    var _join = function( /*args*/ ) {
      var arr = Array.prototype.slice.call(arguments, _join.length);
      return arr.join(separator = '-');
    }

    // Initialize HTML structure
    var html = "";

    // Construct experimental interface container
    html += '<div class="misinformation-wrap">';

    // Define response collection area
    html += '<div class="comprehension-box">';

    // Initialize form structure
    html += '<form id="jspsych-survey-multi-choice-form">';
    
    // Implement feedback collection interface
    html += '<p>Thank you for participating in this study on information processing. ' +
            'Please provide any comments or observations about your experience ' +
            '(If you have no specific comments, please enter "NA").</p>' +
            '<div class="input-group mb-3">' +
            '<div><textarea id="jspsych-survey-comments-text" class="form-control" ' +
            'cols="80" rows="10" name="comments"></textarea></div>' +
            '</div>';

    // Implement response submission mechanism
    html += '<input type="submit" id="' + plugin_id_name + '-next" class="' + 
            plugin_id_name + ' jspsych-btn"' + 
            (trial.button_label ? ' value="' + trial.button_label + '"': '') + 
            '"></input>';

    // Finalize HTML structure
    html += '</form>';
    html += '</div></div>';

    // Render interface
    display_element.innerHTML = html;

    // ---------------------------------- //
    // Response Processing Configuration   //
    // ---------------------------------- //

    // Implement viewport management
    window.onbeforeunload = function () {
      window.scrollTo(0, 0);
    }

    // Configure response submission handler
    document.querySelector('form').addEventListener('submit', function(event) {
      event.preventDefault();

      // Extract participant feedback
      user_comments = display_element.querySelector('#jspsych-survey-comments-text').value;

      // Clear interface
      display_element.innerHTML += '';

      // Advance experimental progression
      jsPsych.finishTrial();
    });
  };

  return plugin;
})();