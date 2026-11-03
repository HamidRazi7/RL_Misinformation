/**
 * jspsych-misinformation-questions
 *
 *
 * Based on code by Sam Zorowitz https://github.com/nivlab/jspsych-demos/tree/main/tasks/horizons
 **/

var questions = {
	active: false,
	p: 1,
	responses: ['', '', '', '', '', ''],
	display_element: null,
	steps: [1],
	pages_html: [
		//p0
		'',
		//p1 q1
		'<div class="horizons-wrap text-start p-4" id="questions-timeline-div-id-1">'+
		'<p>1.	1.	In the experiment just now, how did you try to react if an option you chose received a reward (10 points) but this turned out to be an inaccurate piece of information:</p>'+
		'<ol style="list-style-type:none;">'+
			'<li>(a) Ignored the reward I was shown. <input type="radio" name="questions_q1" value="a" onclick="questions.enter(event)"></li>'+
			'<li>(b) Avoided selecting this option in the future.<input type="radio" name="questions_q1" value="b" onclick="questions.enter(event)"></li>'+
			'<li>(c) Selected this option more in the future.<input type="radio" name="questions_q1" value="c" onclick="questions.enter(event)"></li>'+
			'<li>(d) other<input type="radio" name="questions_q1" value="d" onclick="questions.enter(event)"></li>'+
		'</ol>'+
		'</div>',
		//p2 q2
		'<div class="horizons-wrap text-start p-4" id="questions-timeline-div-id-2">'+
		'<p>2.	Tell us more about why you would try to avoid selecting this option in the future. Was it because:</p>'+
		'<ol style="list-style-type:none;">'+
			'<li>(a) You actually got the opposite of what was shown in these cases (i.e., 1 not 10).<input type="radio" name="questions_q2" value="a" onclick="questions.enter(event)"></li>'+
			'<li>(b) You wanted to avoid being falsely told you got 10 in the future.<input type="radio" name="questions_q2" value="b" onclick="questions.enter(event)"></li>'+
			'<li>(c) Another reason.<input type="radio" name="questions_q2" value="c" onclick="questions.enter(event)"></li>'+
		'</ol>'+
		'</div>',
		//p3 q3
		'<div class="horizons-wrap text-start p-4" id="questions-timeline-div-id-3">'+
		'<p>3.	Try as best you can to briefly describe the strategy you used in these cases by typing into the box below (you must answer (do not refresh), then press Enter to proceed):</p>'+
		'<textarea name="questions_q3" rows="10" cols="80"></textarea>'+
		'</div>',
		//p4 q4
		'<div class="horizons-wrap text-start p-4" id="questions-timeline-div-id-4">'+
		'<p>4.	In cases like these, which of the following did you think:</p>'+
		'<ol style="list-style-type:none;">'+
			'<li>(a) The real outcome you got was the opposite to the one you were shown (i.e., 1 not 10)<input type="radio" name="questions_q4" value="a" onclick="questions.enter(event)"></li>'+
			'<li>(b) The real outcome you got could have been the same (10) but it could also have been different (1) to the one you were shown.<input type="radio" name="questions_q4" value="b" onclick="questions.enter(event)"></li>'+
		'</ol>'+
		'</div>',
		//p5 q5
		'<div class="horizons-wrap text-start p-4" id="questions-timeline-div-id-5">'+
		'<p>5.	Please let us know if you have any other thoughts. </p>'+
		'<textarea name="questions_q5" rows="10" cols="80"></textarea>'+
		'</div>'
	],
	timeline: null,
	enter: function(event) {
		let name = event.target.name;
		let n_id = parseInt(name.substr(11));
		if (this.p == n_id) {
			//
		} else if (this.p < n_id) {
			return;
		} else {
			this.p = n_id;
			for (let g = this.p; g < this.responses.length; g++) {
				this.responses[g] = '';
			}
			for (let g = this.steps.length - 1; g >= 0; g--) {
				if (this.steps[g] != this.p) {
					this.steps.pop();
				} else {
					break;
				}
			}
		}
		let match = this.display_element.querySelector('#questions-timeline-div-id-'+this.p);
		let value = null;
		try {
			if (this.p == 1 || this.p == 2 || this.p == 4) {
				value = match.querySelector("input[type=radio]:checked").value;
			} else if (this.p == 3 || this.p == 5) {
				value = match.querySelector("textarea").value;
			} else if (this.p == 0) {
				value = 'q0';
			} else {
				value = null;
			}
		} catch(err) {}
			
		jsPsych.finishTrial({
			value
		});
	},
	on_finish: function() {
		questions.active = false;
	},
}

jsPsych.plugins['misinformation-questions'] = (function() {
  var plugin = {};

  plugin.info = {
    name: 'misinformation-questions',
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
    questions.display_element = display_element;
    var html = '';

    // Insert CSS
    html += `<style>
    .horizons-wrap {
      /*height: 100vh;*/
      width: 100vw;
    }
    </style>`;

    // Add factory machine parts (back).
	questions.steps.forEach(value => {
		html += questions.pages_html[value];
	});
	
	html += '<input type="button" id="scroll-bottom-button" value="" style="background-color:rgb(255, 255, 255, 0.0); border:0px solid white; width:1px; height:1px;">';
    // Display HTML
    display_element.innerHTML = html;
	questions.steps.forEach(step => {
		let match = display_element.querySelector('#questions-timeline-div-id-'+step);
		let value = questions.responses[step];
		try {
			if (step == 1 || step == 2 || step == 4) {
				match.querySelector("input[value="+value+"]").setAttribute('checked', 'checked');
				match.querySelector("input[value="+value+"]").parentNode.style.color = 'red';
			} else if (step == 3 || step == 5) {
				match.querySelector("textarea").value = value;
			} else {}
		} catch (err) {}
	});
	display_element.querySelector('#scroll-bottom-button').focus();
  };

  return plugin;
})();

questions.timeline = [
	{
		type: "html-keyboard-response",
		stimulus: function() {
			return '<div class="horizons-wrap text-start p-4" id="questions-timeline-div-id-0">'+
				'<p>Before we finish, it would really help us if we could spend a moment to answer a couple of questions about the experiment you have just completed.</p>'+
				'<p>Press enter to continue.</p>'+
				'</div>';
		},
		choices: [/*'ArrowRight',*/ 'Enter'],
	},
	{
		timeline: [
			{
				type: 'misinformation-questions',
				on_finish: function() {
					questions.active = true;
				},
			},
		],
		loop_function: function(data) {
			let value = data.values().slice(-1)[0].value;
			if (!value || value == '') {
				alert('Please answer the question so you could finish the experiment.');
				return true;
			}
			questions.responses[questions.p] = value;
			switch (questions.p) {
					case 0:
						questions.p++;
						break;
					case 1:
						if (value == 'b') {
							questions.p++;
						} else if (value == 'd') {
							questions.p = 3;
						} else {
							questions.p = 5;
						}
						break;
					case 2:
						if (value == 'c') {
							questions.p = 3;
						} else if (value == 'b') {
							questions.p = 4;
						} else {
							questions.p = 5;
						}
						break;
					case 3:
						questions.p = 5;
						break;
					case 4:
						questions.p = 5;
						break;
					case 5:
						return false;
						break;
				}
				questions.steps.push(questions.p);
				
				return true;
		},
	},
];

window.addEventListener("keydown", (event) => {
    if (questions.active) {
		if (event.code === "Enter") {
			questions.enter(event);
		}
	}
});
