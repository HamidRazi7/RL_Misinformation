/**
 * jspsych-misinformation-comprehension
 *
 * plugin for running the comprehension check for the misinformation task
 *
 * Based on code by Sam Zorowitz https://github.com/nivlab/jspsych-demos/tree/main/tasks/horizons
 **/

jsPsych.plugins['misinformation-comprehension'] = (function() {
  var plugin = {};

  plugin.info = {
    name: 'misinformation-comprehension',
    description: '',
    parameters: {
      button_label: {
        type: jsPsych.plugins.parameterType.STRING,
        pretty_name: 'Button label',
        default:  'Continue',
        description: 'Label of the button.'
      }
    }
  }
  plugin.trial = function(display_element, trial) {

    // Plug-in setup
    var plugin_id_name = "jspsych-survey-multi-choice";
    var plugin_id_selector = '#' + plugin_id_name;
    var _join = function( /*args*/ ) {
      var arr = Array.prototype.slice.call(arguments, _join.length);
      return arr.join(separator = '-');
    }

    // ---------------------------------- //
    // Define Prompts          //
    // ---------------------------------- //

    // Define comprehension check questions.
    var prompts = [
      "1.After making your choice, you will be shown points for: ",
      "2.Points can be added to your overall total in which type of trials: ",
      "3.Points you earn over the course of the experiment will: ",
      '<p>4.Please take a look at the example below. Which of the following statements is true: </p><p style="text-align:center;"><img src="./img/c_q_4.png" /></p>',
      '<p>5.Please take a look at the example below. Which of the following statements is true: </p><p style="text-align:center;"><img src="./img/c_q_5.png" /></p>',
      '<p>6.To make sure you are paying attention to the accuracy ratings, sometimes you will be asked about the last rating you saw like in the example below. Which of the following is true: </p><p style="text-align:center;"><img src="./img/c_q_6.png" /></p>',



    ];
	var options = [
		[// 1
			{value: 'a', lable: 'The symbol you chose.'},
			{value: 'b', lable: 'The symbol you did not choose.'},
			{value: 'c', lable: 'Both symbols (the symbol you chose and the symbol you did not choose).'},
			{value: 'd', lable: 'One of the two symbols (either the symbol you chose or the symbol you did not choose).'},
		],
		[// 2
			{value: 'a', lable: 'All trials'},
			{value: 'b', lable: 'Only trials where you see the number of points for the option you chose.'},
			{value: 'c', lable: 'Only trials where you see the number of points for the option you did not choose.'},
			{value: 'd', lable: 'Only trials where the number of points you were shown was inaccurate (0% accuracy rating).'},
			{value: 'e', lable: 'Just trials where the number of points you were shown was accurate (100% accuracy rating).'},
		],
		[// 3
			{value: 'a', lable: 'have no influence your bonus payment'},
			{value: 'b', lable: 'contribute to your bonus payment in the following way - the more points you get the<br>higher your bonus payment will be'},
			{value: 'c', lable: 'contribute to your bonus payment in the following way – the more points you get the<br>lower your bonus payment will be'},
		],
		[// 4
			{value: 'a', lable: 'The outcome you did not choose received 10 points.'},
			{value: 'b', lable: 'The outcome you did choose received 10 points.'},
			{value: 'c', lable: 'You do not know how many points either option gave you on this trial.'},
		],
		[// 5
			{value: 'a', lable: 'The outcome you did not choose received 10 points'},
			{value: 'b', lable: 'The outcome you did choose received 10 points.'},
			{value: 'c', lable: 'You do not know how many points either option gave you on this trial.'},
		],

		[// 6
			{value: 'a', lable: 'Try your best on these questions but the answers will not impact your bonus payment'},
			{value: 'b', lable: 'Try your best on these questions - your bonus payment can be reduced by half if you fail to get most of them correct.'},
			
		],
    
	];

    // Define correct answers.
    var correct = ["d", "a", "b", "c", "a", "b"];

    // ---------------------------------- //
    // Section 2: Define HTML             //
    // ---------------------------------- //

    // Initialize HTML
    var html = "";

    // Insert CSS
    html += `<style>
    .horizons-wrap {
      height: 100vh;
      width: 100vw;
    }
    .comprehension-box {
      position: absolute;
      top: 10%;
      left: 50%;
      -webkit-transform: translate3d(-50%, 0, 0);
      transform: translate3d(-50%, 0, 0);
      width: 70%;
      height: 100%;
      background: #ffffff;
      line-height: 1.25em;
    }
    .comprehension-box .jspsych-survey-multi-choice-question {
      margin-top: 0em;
      margin-bottom: 1.0em;
      text-align: left;
      padding-left: 2em;
      font-size: 1vw;
    }
    .comprehension-box .jspsych-survey-multi-choice-horizontal .jspsych-survey-multi-choice-text {
      text-align: left;
      margin: 0em 0em 0em 0em
    }
    .comprehension-box .jspsych-survey-multi-choice-horizontal .jspsych-survey-multi-choice-option {
      /*display: inline-block;*/
      margin: 0.33em 1em 0em 1em;
    }
    .comprehension-box .jspsych-survey-multi-choice-option input[type='radio'] {
      margin-right: 0.5em;
      width: 1.2em;
      height: 1.2em;
    }
    </style>`;

    // Add factory machine parts (back).
    html += '<div class="horizons-wrap">';

    // form element
    var trial_form_id = _join(plugin_id_name, "form");
    display_element.innerHTML += '<form id="'+trial_form_id+'"></form>';

    // Show preamble text
    html += '<div class="comprehension-box">'
    html += '<div class="jspsych-survey-multi-choice-preamble"><h4 style="font-size: 1.5vw; margin-block-start: 1em; margin-block-end: 1em">Please answer the questions below:</div>';

    // Initialize form element
    html += '<form id="jspsych-survey-multi-choice-form">';

    // Iteratively add comprehension questions.
    for (i = 0; i < prompts.length; i++) {

      // Initialize item
      html += `<div id="jspsych-survey-multi-choice-${i}" class="jspsych-survey-multi-choice-question jspsych-survey-multi-choice-horizontal" data-name="Q${i}">`;

      // Add question text
      html += `<p class="jspsych-survey-multi-choice-text survey-multi-choice">${prompts[i]}</p>`;

      // Options
	  for (let j = 0; j < options[i].length; j++) {
		html += `<div id="jspsych-survey-multi-choice-option-${i}-${j}" class="jspsych-survey-multi-choice-option">`;
		html += `<input type="radio" name="jspsych-survey-multi-choice-response-${i}" id="jspsych-survey-multi-choice-response-${i}-${j}" value=${options[i][j].value} required>`;
		html += `<label class="jspsych-survey-multi-choice-text" for="jspsych-survey-multi-choice-response-${i}-${j}">(${options[i][j].value}) ${options[i][j].lable}</label>`;
		html += '</div>';
	  }
	  
      // Close item
      html += '</div>';

    }

    // add submit button
    html += '<input type="submit" id="'+plugin_id_name+'-next" class="'+plugin_id_name+' jspsych-btn m-3"' + (trial.button_label ? ' value="'+trial.button_label + '"': '') + '"></input>';

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

      // Measure response time
      var endTime = performance.now();
      var response_time = endTime - startTime;

      // Gather responses
      var responses = [];
      var num_errors = 0;
      for (var i=0; i<prompts.length; i++) {

        // Find matching question.
        var match = display_element.querySelector('#jspsych-survey-multi-choice-'+i);
        var val = match.querySelector("input[type=radio]:checked").value;

        // Store response
        responses.push(val)

        // Check accuracy
        if ( correct[i] != val ) {
          num_errors++;
        }

      }

      // store data
      var trial_data = {
        "responses": responses,
        "num_errors": num_errors,
        "rt": response_time
      };

      // clear html
      display_element.innerHTML += '';

      // next trial
      jsPsych.finishTrial(trial_data);

    });

    var startTime = performance.now();
  };

  return plugin;
})();
