//------------------------------------//
// Define parameters.
//------------------------------------//

// Define comprehension threshold.
var max_errors = 0;

//------------------------------------//
// Define instructions.
//------------------------------------//

// Define image scaling CSS.
const style = "width:auto; height:auto; max-width:100%; max-height:75vh; min-height:50vh;";


// Comprehension check.
var comprehension = {
  type: 'misinformation-comprehension'
}

var description = {
	p: 0,
	i: 0,
	pages_text_lines: [

		[// 1
			'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
			'<p style="text-align:center"><img src="./img/d_p_2.png" /></p>In this experiment you will play a game in which you need to choose between different symbols<br>like the two displayed here.', 
			'Some symbols will often give you points when you choose them.',
			'Some symbols will often lose you points when you choose them. ',
			'Note: We give you some points to start the task with. This means that you cannot end the task with a negative number of points. <br> But it is possible to end the task with 0 points (and no bonus payment) if you lose lots of points and fail to win many points through the course of the experiment. ',
			'The goal of the game is to try and choose the symbols which will give you the most points and lose you the least points. <br> By doing this, you will earn the most points over the course of the experiment. <br> And the more points you earn, the higher your bonus payment will be.',
		],
		[// 2
			'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
			'Learning which symbol to choose is not always easy. Let’s try to understand more about this.',
			'On each trial, you will be asked to choose between two symbols.',
			'<ul><li>To select the symbol displayed on the left, press the left arrow key.</li><li>To select the symbol on the right, press the right arrow key.</li></ul>',
			'There is no time limit for making a choice - but no need to overthink it!',
			'Symbols do not always appear on the same side of the screen - sometimes they’ll appear on the left, other times on the right. <br> So pay close attention to which symbol you are choosing.',
		],
		[// 4
			'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
			'After you make your choice, a star will appear above the symbol you chose, confirming your<br>choice. ',
			'In the example below, the * above the symbol on the right indicates this symbol was the one<br>you selected.<p style="text-align:center"><img src="./img/d_p_4.png" /></p>',
			'You will also be shown how many points one of the two symbols won or lost. ',
			'Sometimes this will be shown for the symbol that you chose. <br> In the example above for instance, the points (10) collected are shown below the symbol you chose (on the right). <br> This means that this symbol won you 10 points on this trial. ',
			'In this example, you are not shown how many points the other symbol (on the left) would have<br>given you if you had chosen it (instead you see xx underneath this symbol).',
		],
		[// 5
			'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
			'On other occasions, you will be shown what the outcome was for the symbol you did not<br>choose (i.e. what you would have got, if you had chosen the other symbol instead). ',
			'For instance, in the example below, you chose the option on the right(indicated by the *). <br> But you are shown how many points the symbol on the left would have lost if you had chosen this option instead.<p style="text-align:center"><img src="./img/d_p_5.png" /></p>',
			'In this example, the symbol that you chose (on the right) still wins or loses you points that affect <br> your points total. You are just not shown what this is on this occasion (you see xx<br>instead).',
			'Note: points won or lost for options you did not choose never influence your points total; this is just for your information.',
		],
		[// 6
			'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
			'Unfortunately, there is a glitch in the game.',
			'This causes the points you are shown after you make a choice to be faulty on some occasions.  ',
			'When this happens, you are shown the points you would have won or lost if you were playing an entirely different game. <br> You can ignore this therefore as they do not apply here and do not contribute to your points total.',
			'Think about it this way if it helps: just as you can play different games with the same<br>pack of playing cards, the symbols you choose between here can win and lose different amount of points in different games. <br> Sometimes you are shown the points from a different game by mistake. ',
			'When this mistake happens, the points that you see are unrelated to the points each symbol actually wins or loses on this trial. <br> The symbols and your choices do still win/lose points on these trials - you are just not shown what these are.   ',
			'The actual points you win/lose on these trials could be the same as the points you were shown by mistake. But they could also be different altogether. ',
			
		],
		[// 7
			'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
			'To help you identify when a glitch has occurred, a sign will appear.',
			'When you see a cross sign, this means that the information (points won or lost) <strong>was not</strong> accurate (i.e. a glitch has occurred) <br> and you can ignore the information you just saw.',
			'An example of this is shown below::<p style="text-align:center"><img src="./img/d_p_6.png" /></p> ',
			
		],
		[// 8
			'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
			'When you see a tick, this means that the information you were just shown <strong>was</strong> accurate (i.e. a glitch has not occurred). <br> The points you saw are the actual points you won or lost.',
			 'An example of this is shown below:.<p style="text-align:center"><img src="./img/d_p_7.png" /></p>',
		],
        [// 9
					'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
'To make sure you are paying attention to the accuracy ratings, sometimes you will be asked to indicate whether the last information you saw was accurate or inaccurate. <p style="text-align:center"><img src="./img/c_q_6.png" /></p> ', 
			'You need to get these questions correct most of the time (75% or more). <br> If you fail to do this, your bonus payment will be reduced by half.',
			'You will have the opportunity to take a break during the experiment.',
			'Remember that your task is to try to choose symbols that win real points the most and lose real points the least. <br> To do this you will need to use the accurate feedback you receive.  <br> At the end of the experiment, the total number of points you have will be converted into a bonus payment. The more points, the higher the bonus payment will be. <br> You will play one block of trials.',
		],
		[// 10
			'<p style="text-align:center; width:'+parseInt(window.innerWidth*91/100)+'px;">Press enter to advance instructions</p>',
			'OK, if you have finished reading the instructions, now we have a quiz to check you have<br>understood everything. ',
			'You need to get all questions correct in the quiz before we progress to the next part. ',
			'If you get any of the questions wrong you will need to reread the instructions and retake the<br>quiz.',
		]
	],
	timeline: null,
}
description.timeline = [
	{
		timeline: [
			{
				type: "html-keyboard-response",
				stimulus: function() {
					let code = '<div style="position:absolute; top:50px; left:50px; text-align:left;">';
					for (let l = 0; l <= description.i; l++) {
						code+= '<p>'+description.pages_text_lines[description.p][l]+'</p>';
					}
					return code+'</div>';
				},
				choices: [/*'ArrowRight',*/ 'Enter'],
			},
		],
		loop_function: function(data) {
			let key = jsPsych.data.get().last(1).values()[0];
			if (jsPsych.pluginAPI.compareKeys(key.response, 'Enter')) {
				description.i++;
				if (description.i == description.pages_text_lines[description.p].length) {
					description.i = 0;
					description.p++;
				}
			} else if (jsPsych.pluginAPI.compareKeys(key.response, 'ArrowRight')) {
				description.i = 0;
				description.p++;
			}
			
			if (description.p == description.pages_text_lines.length) {
				return false;
			} else {
				return true;
			}
		},
	},
];

var i_blocks = functions.new_blocks();
i_blocks.set_blocks_trials(i_blocks_trials, i_catch_trial_size, "Now you will engage in a few practice trials", "End of practice trials. The main experiment begins now.", "Practice Trial: ", "Choose an option using the left and right arrow keys on your keyboard");

var great = {
	type: "html-keyboard-response",
	stimulus: function() {
		return '<p>Great, you got all the questions right! Now, to familiarize you with the game, we will start with<br>a training session. This is just for practice so the points you win and lose here do not actually<br>count. After this we will begin the game for real.</p><p>When you are ready, press any button to begin the training...</p>';
	},
}
			
// Define instructions loop.
var instructions = {
	timeline: [
		{
			timeline: [
				description,
				comprehension,
			],
			loop_function: function(data) {
				// Extract number of errors.
				const num_errors = data.values().slice(-1)[0].num_errors;
				// Check if instructions should repeat.
				if (num_errors > max_errors) {
					alert('You responded incorrectly, please review the instructions and try again.');
					setTimeout(window.location.reload(), 2000);
					return true;
				} else {
					return false;
				}
			}
		},
		great,
		i_blocks,
	],
	
};


