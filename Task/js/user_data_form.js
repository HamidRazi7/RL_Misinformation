/**
 * jspsych-misinformation-user-data-form
 * Graph
 *
 * plugin for running the user-data-form send for the misinformation task
 *  * Based on code by Sam Zorowitz https://github.com/nivlab/jspsych-demos/tree/main/tasks/horizons
 *
 **/

jsPsych.plugins['misinformation-user-data-form'] = (function() {
  var plugin = {};

  plugin.info = {
    name: 'misinformation-user-data-form',
    description: '',
    parameters: {
      button_label: {
        type: jsPsych.plugins.parameterType.STRING,
        pretty_name: 'Button label',
        default:  'Send',
        description: 'Label of the button.'
      }
    }
  }
  plugin.trial = function(display_element, trial) {

    // Plug-in setup
    var plugin_id_name = "jspsych-survey-user-data-form-send";
    var plugin_id_selector = '#' + plugin_id_name;
    var _join = function( /*args*/ ) {
      var arr = Array.prototype.slice.call(arguments, _join.length);
      return arr.join(separator = '-');
    }

    // Initialize HTML
    var html = "";

    // Add factory machine parts (back).
    html += '<div class="horizons-wrap">';

    // Show preamble text
    html += '<div class="comprehension-box">';

    // Initialize form element
    html += '<form id="jspsych-survey-multi-choice-form">';
	
	html += '<div class="input-group mb-3">'+
          '<span class="input-group-text" id="basic-addon3">What is your age?</span>'+
          '<input type="text" class="form-control" id="jspsych-survey-user-age-text" aria-describedby="basic-addon3">'+
        '</div>';
	
	html += '<fieldset class="mb-3" id="jspsych-survey-multi-choice-user-data">'+
            '<legend>What is your gender?</legend>'+
            '<div class="form-check">'+
              '<input type="radio" name="radios" class="form-check-input" value="male" id="jspsych-survey-multi-choice-response-user-male" required>'+
              '<label class="form-check-label" for="exampleRadio1" align="left">-Male</label>'+
            '</div>'+
            '<div class="mb-3 form-check">'+
              '<input type="radio" name="radios" class="form-check-input" value="female" id="jspsych-survey-multi-choice-response-user-female" required>'+
              '<label class="form-check-label" for="exampleRadio2" align="left">-Female</label>'+
            '</div>'+
			'<div class="mb-3 form-check">'+
              '<input type="radio" name="radios" class="form-check-input" value="prefer not to say" id="jspsych-survey-multi-choice-response-user-prefer-not-to-say" required>'+
              '<label class="form-check-label" for="exampleRadio3">-Prefer not to say</label>'+
            '</div>'+
          '</fieldset>';

    // add submit button
    html += '<input type="submit" id="'+plugin_id_name+'-next" class="'+plugin_id_name+' jspsych-btn"' + (trial.button_label ? ' value="'+trial.button_label + '"': '') + '"></input>';

    // End HTML
    html += '</form>';
    html += '</div></div>';

    // Display HTML
    display_element.innerHTML = html;

    // ---------------------------------- //
    // Section 2: jsPsych Functions       //
    // ---------------------------------- //

    // Scroll to top of screen.
    window.onbeforeunload = function () {
      window.scrollTo(0, 0);
    }

    // Detect submit button press
    document.querySelector('form').addEventListener('submit', function(event) {
      event.preventDefault();

        // Find matching question.
	user_age = display_element.querySelector('#jspsych-survey-user-age-text').value;
        var match = display_element.querySelector('#jspsych-survey-multi-choice-user-data');
        user_gender = match.querySelector("input[type=radio]:checked").value;

      // clear html
      display_element.innerHTML += '';

      // next trial
      jsPsych.finishTrial();

    });

  };

  return plugin;
})();