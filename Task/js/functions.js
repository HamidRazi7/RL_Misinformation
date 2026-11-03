var functions = {};
			
			functions.new_blocks = function() {
				var out = {
					timeline: [],
					block_c:0,
					trial_id:-1,
					catch_trial_ids: [],
					get_block: function(block_num = null) {
						if (block_num == null) { block_num = this.block_c; }
						
						return this.timeline[block_num-1];
					},
					get_trial: function(block_num = null, trial_num = null) {
						if (block_num == null) { block_num = this.block_c; }
						if (trial_num == null) { trial_num = this.timeline[block_num-1].trial_c; }
						
						return this.timeline[block_num-1].timeline[1].timeline[trial_num-1];
					},
					set_blocks_trials: function(blocks_meta, catch_trial_size, block_start_message = null, block_end_message = null, trial_top_message = null, trial_down_message = null) {
						var blocks = this;
						let all_trials_size = 0;
						for (let i = 0; i < blocks_meta.length; i++) {
							blocks.timeline.push(functions.new_block(blocks, blocks_meta[i], block_start_message, block_end_message, i+1, blocks_meta.length));
							
							let trials_size = 0;
							for (let q = 0; q < blocks_meta[i].images_data.length; q++) {
								trials_size+= blocks_meta[i].images_data[q].size;
							}
							all_trials_size+= trials_size;
						}
						
						let catch_trial_ids = [];
						for (let l = 0; l < catch_trial_size; l++) {
							while(true) {
								let r_ = Math.floor(Math.random()*all_trials_size);
								if (!functions.in_array(r_, catch_trial_ids)) {
									catch_trial_ids[l] = r_;
									break;
								}
							}
						}
						blocks.catch_trial_ids = catch_trial_ids;
						
						for (let i = 0; i < blocks.timeline.length; i++) {
							blocks.timeline[i].set_trials(blocks.get_block(i+1), trial_top_message, trial_down_message);
						}
					},
				};
				return out;
			}
			
			functions.new_block = function(blocks, block_meta, block_start_message, block_end_message, block_num, blocks_size) {
				var new_block = {
								timeline: [],
								get_blocks:function() { return blocks; },
								trial_c:1,
								data_source_img:'./img/source-block-'+block_num+'.jpg',
								block_meta: block_meta,
								block_middle: block_meta.block_middle,
								chances:[],
								set_trials: function(new_block, trial_top_message, trial_down_message) {
									let size_array = new Array();
									for (let i = 0; i < block_meta.images_data.length; i++) {
										size_array[i] = block_meta.images_data[i].size;
									}
									
									let trials_size = 0;
									for (let i = 0; i < size_array.length; i++) {
										trials_size+= size_array[i];
									}
									for (let i = 0; i < trials_size; i++) {
										let new_trial = functions.new_trial(this, block_meta, trial_top_message, trial_down_message);
										this.timeline[1].timeline.push(new_trial);
									}
									this.timeline[1].timeline = functions.sort_random(this.timeline[1].timeline);
									for (let i = 0; i < trials_size; i++) {
										let new_trial = this.timeline[1].timeline[i];
										let block = this;
										new_trial.timeline = [
									{
										type: "html-keyboard-response",
										stimulus: function() {
											return '<img src="./img/fixation-cross.png" />';
										},
										choices: jsPsych.NO_KEYS,
										trial_duration: fixation_cross_1_time*new_trial.trial_fixation_time,
										on_finish: function() {}
									},
									{
										type: "html-keyboard-response",
										on_start: function() {
											new_trial.start_time = Date.now();
										},
										stimulus: function() {
											return functions.html_code(new_trial, 1);
										},
										choices: ['ArrowLeft', 'ArrowRight'],
										on_finish: function() {
											new_trial.reaction_time = Date.now() - new_trial.start_time;
										},
									},
									{
										type: "html-keyboard-response",
										stimulus: function() {
											var data = jsPsych.data.get().last(1).values()[0];
											if (jsPsych.pluginAPI.compareKeys(data.response, 'ArrowLeft')) {
												return functions.f_img(new_trial, 'l');
											} else if (jsPsych.pluginAPI.compareKeys(data.response, 'ArrowRight')) {
												return functions.f_img(new_trial, 'r');
											}
										},
										choices: jsPsych.NO_KEYS,
										trial_duration: choice_to_feedback_time,
										on_finish: function() {
											functions.replay(new_trial);
										}
									},
									{
										type: "html-keyboard-response",
										stimulus: function() {
											return functions.html_code(new_trial, 3);
										},
										choices: jsPsych.NO_KEYS,
										trial_duration: feedback_to_next_time,
										on_finish: function() {
											//block.trial_c++;
										}
									},
									{
										type: "html-keyboard-response",
										stimulus: function() {
											return '<img src="./img/fixation-cross.png" />';
										},
										choices: jsPsych.NO_KEYS,
										trial_duration: fixation_cross_2_time*new_trial.trial_fixation_time,
										on_finish: function() {}
									},
									{
										type: "html-keyboard-response",
										stimulus: function() {
											let img = 'div-white.png';
											if (new_trial.source_feedback === true) {
												img = 'div-yellow.png';
											} else if (new_trial.source_feedback === false) {
												img = 'div-white.png';
											}
											return '<img src="./img/' + img + '" />';
										},
										choices: jsPsych.NO_KEYS,
										trial_duration: trial_timeline3_to_timeline4_time,
										on_finish: function() {
											block.trial_c++; // *******
										}
									},
								];
				if (functions.in_array(new_trial.id, block.get_blocks().catch_trial_ids)) {
					new_trial.timeline.push({
						type: "html-keyboard-response",
						on_start: function() {},
						stimulus: function() {
							return '<div><h4>Was the last information you just saw accurate or inaccurate?</h4>'+
							'<h6 class="text-danger" style="float:left;">Accurate&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</h6>'+
							'<h6 class="text-danger" style="float:right;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Inaccurate</h6>'+
							'</div>';
						},
						choices: ['ArrowLeft', 'ArrowRight'],
						on_finish: function() {
							var data = jsPsych.data.get().last(1).values()[0];
							if (jsPsych.pluginAPI.compareKeys(data.response, 'ArrowLeft')) {
								new_trial.catch_trial_response = 'Accurate';
							} else if (jsPsych.pluginAPI.compareKeys(data.response, 'ArrowRight')) {
								new_trial.catch_trial_response = 'Inaccurate';
							}
						},
					});
					new_trial.timeline.push({
						type: "html-keyboard-response",
						stimulus: function() {
							let left_ = (new_trial.catch_trial_response == 'Accurate')? '<img src="./img/star.png" />' : '';
							let right_ = (new_trial.catch_trial_response == 'Inaccurate')? '<img src="./img/star.png" />' : '';
							return '<div><h4>Was the last information you just saw accurate or inaccurate?</h4>'+
							'<h6 class="text-danger" style="float:left;">Accurate&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<div>'+
							left_+'</div></h6>'+
							'<h6 class="text-danger" style="float:right;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Inaccurate<div>'+
							right_+'</div></h6>'+
							'</div>';
						},
						choices: jsPsych.NO_KEYS,
						trial_duration: 1000,
						//on_finish: function() {}
					});
				}
				
				let bool_interrupt = false;
				for (let is = 0; is < block_meta.interrupts.length; is++) {
					if (i == block_meta.interrupts[is]) {
						bool_interrupt = true;
						break;
					}
				}
				if (bool_interrupt) {
					new_trial.timeline.push({
						type: "html-keyboard-response",
						stimulus: function() {
							return '<p>Thanks for doing the experiment. You can take a break now if you want. Note that the symbols do not change before or after break. Press any key to continue when you’re ready. </p>';
						},
					});
				}
				
									}
									//////////////////////////////////////////////////////////////////////////////
				var trial_size = new_block.timeline[1].timeline.length;
				
				let trials_type = functions.set_half_true_1(trial_size);
				for (let i = 1; i <= trials_type.length; i++) {
					new_block.timeline[1].timeline[i-1].trial_type = trials_type[i-1];
				}
				
				let feedbacks_type = functions.set_half_true_1(trial_size, 'i');
				for (let i = 1; i <= feedbacks_type.length; i++) {
					new_block.timeline[1].timeline[i-1].feedback_type = feedbacks_type[i-1];
				}
				
				let trials_data = new Array();
				for (let i = 0; i < new_block.block_meta.images_data.length; i++) {
					for (let j = 0; j < new_block.block_meta.images_data[i].size; j++) {
						trials_data.push({
							data:new_block.block_meta.images_data[i], 
							reverse:false, 
							condition:new_block.block_meta.images_data[i].name, 
							condition_type:new_block.block_meta.images_data[i].condition_type,
						});
					}
				}
				trials_data = functions.sort_random(trials_data);
				for (let i = 0; i < new_block.block_meta.images_data.length; i++) {
					let size_reverse_false = 0;
					for (let j = 0; j < trials_data.length; j++) {
						if (trials_data[j].condition == new_block.block_meta.images_data[i].name) {
							size_reverse_false++;
							if ((new_block.block_meta.images_data[i].block_middle !== null) && (size_reverse_false > new_block.block_meta.images_data[i].block_middle)) {
								trials_data[j].reverse = true;
							}
						}
					}
				}
				
				let img_chance = functions.set_half_true_1(trial_size);
				for (let i = 0; i < trial_size; i++) {
					let trial = new_block.timeline[1].timeline[i];
					trial.condition = trials_data[i].condition;
					trial.condition_type = trials_data[i].condition_type;
					trial.reverse = trials_data[i].reverse;
					//trial.trial_type = trials_data[i].trial_type;
					//trial.feedback_type = trials_data[i].feedback_type;
					let chance_1_2 = functions.chance_1_2(trials_data[i], i+1, trial.trial_type);
					let outcomes_chance_1_2 = functions.outcomes_chance_1_2(trials_data[i], i+1, trial.trial_type);
					if (img_chance[i]/*trials_data[i].img_chance*/ == true) {
						trial.div_left_data.img_type = 1;
						trial.div_right_data.img_type = 2;
						trial.div_left_data.src = trials_data[i].data.img_1.src;
						trial.div_right_data.src = trials_data[i].data.img_2.src;
						
						trial.div_left_data.chance = chance_1_2['1'];
						trial.div_right_data.chance = chance_1_2['2'];
						trial.div_left_data.outcomes_chance = outcomes_chance_1_2['1'];
						trial.div_right_data.outcomes_chance = outcomes_chance_1_2['2'];
					} else {
						trial.div_left_data.img_type = 2;
						trial.div_right_data.img_type = 1;
						trial.div_left_data.src = trials_data[i].data.img_2.src;
						trial.div_right_data.src = trials_data[i].data.img_1.src;
						
						trial.div_left_data.chance = chance_1_2['2'];
						trial.div_right_data.chance = chance_1_2['1'];
						trial.div_left_data.outcomes_chance = outcomes_chance_1_2['2'];
						trial.div_right_data.outcomes_chance = outcomes_chance_1_2['1'];
					}
				}
				
				new_block.timeline[1].timeline = functions.sort_random(new_block.timeline[1].timeline);
							//////////////////////////////////////////////////////////////////////////////
									return trials_size;
								},
							};
				new_block.timeline = [
								// define block start message
								{
									type: "html-keyboard-response",
									stimulus: function() {
										if (block_start_message != null) {
											return block_start_message;
										}
										return 'Start of the Block. '+
											'  Press any key to begin.';
									},
									on_finish: function(data){ // this is added here to re-randomise queues before the start of each new block
										functions.block_start(blocks);
									}
								},// show block-start screen
								
								{ timeline: [], },// run a learning block with face images
								
							// define block end message
								{
									type: "html-keyboard-response",
									stimulus: function() {
										if (block_end_message != null) {
											return block_end_message;
										}
										return "End of the Block"
									},
									choices: jsPsych.NO_KEYS,
									trial_duration: 2500,
									on_finish: function(data){ // this is added here to re-randomise queues before the start of each new block
										
									}
								},// show block-end screen
							];
							
				return new_block;
			}
			
			functions.new_trial = function(block, block_meta, trial_top_message, trial_down_message) {
				let trial_fixation_time = block_meta.fixation_cross_times[Math.floor(Math.random()*block_meta.fixation_cross_times.length)];
				var new_trial = {
									id: (function() { block.get_blocks().trial_id++; return block.get_blocks().trial_id; })(),
									timeline: [],
									get_blocks:function() { return block.get_blocks(); },
									get_block:function() { return block; },
									trial_type:null,
									feedback_type:null,
									user_choice:null,
									div_left_data :{img_type:null, src:'', chance:null, outcomes_chance:null,},
									div_right_data:{img_type:null, src:'', chance:null, outcomes_chance:null,},
									reward:'',
									reward_1:'',
									reward_2:'',
									source_feedback:'',
									start_time:null,
									reaction_time:0,
									condition:null,
									condition_type:null,
									reverse:false,
									actual_outcomes:null,
									key_type:null,
									trial_top_message:trial_top_message,
									trial_down_message:trial_down_message,
									catch_trial_response: '',
									trial_fixation_time: trial_fixation_time,
								};
				return new_trial;
			}
			
			functions.chance_1_2 = function(trial_data, trial_num, trial_type) {
				let chance_1_2 = new Array();
				
				if (!trial_data.reverse) {
					if (trial_type == true) {
						chance_1_2['1'] = trial_data.data.img_1.t_true;
						chance_1_2['2'] = trial_data.data.img_2.t_true;
					} else {
						chance_1_2['1'] = trial_data.data.img_1.t_false;
						chance_1_2['2'] = trial_data.data.img_2.t_false;
					}
				} else {
					if (trial_type == true) {
						chance_1_2['1'] = trial_data.data.img_2.t_true;
						chance_1_2['2'] = trial_data.data.img_1.t_true;
					} else {
						/*chance_1_2['1'] = trial_data.data.img_1.t_false;
						chance_1_2['2'] = trial_data.data.img_2.t_false;*/
						chance_1_2['1'] = trial_data.data.img_2.t_false;
						chance_1_2['2'] = trial_data.data.img_1.t_false;
					}
				}
				
				return chance_1_2;
			}
			
			functions.outcomes_chance_1_2 = function(trial_data, trial_num, trial_type) {
				let chance_1_2 = new Array();
				
				if (!trial_data.reverse) {
					chance_1_2['1'] = trial_data.data.img_1.t_true;
					chance_1_2['2'] = trial_data.data.img_2.t_true;
				} else {
					chance_1_2['1'] = trial_data.data.img_2.t_true;
					chance_1_2['2'] = trial_data.data.img_1.t_true;
				}
				
				return chance_1_2;
			}
			
			functions.block_start = function(blocks) {
				blocks.block_c++;
			}
			
			functions.f_img = function(trial, div_type) {
				if (trial.user_choice == null) {
					trial.key_type = (div_type == 'l')? 'left' : 'right';
					let type_left = trial.div_left_data;
					let type_right = trial.div_right_data;
					
					var type, feedback_type_select;
					if (trial.feedback_type == 1) {
						type = (div_type == 'l')? 
						trial.div_left_data : 
						trial.div_right_data;
						
						feedback_type_select = div_type;
					} else {
						type = (div_type == 'r')? 
						trial.div_left_data : 
						trial.div_right_data;
						
						feedback_type_select = (div_type == 'l')? 'r' : 'l';
					}
					
					let choice = (div_type == 'l')? 
						trial.div_left_data.img_type : 
						trial.div_right_data.img_type;
						
					trial.user_choice = 
						{div_type:div_type, feedback_type_select:feedback_type_select, choice:choice, type:type, type_left:type_left, type_right:type_right};
						
					return functions.html_code(trial, 2);
				}
			}
			
			functions.html_code = function(trial, timeline) {
				var l_star = '', r_star = '';
				var l_reward = '', r_reward = '';
				var user_choice = trial.user_choice;
				if (user_choice != null) {
					if (user_choice.div_type == 'l') {
						l_star = '<img src="./img/star.png" />';
					} else {
						r_star = '<img src="./img/star.png" />';
					}
					
					if (trial.reward !== '') {
						if (user_choice.feedback_type_select == 'l') {
							l_reward = trial.reward;
							r_reward = 'xx';
						} else {
							l_reward = 'xx';
							r_reward = trial.reward;
						}
					}
				}
				
				     if (l_reward ==  10) { l_reward = '10'; }
				else if (l_reward == -10) { l_reward = '-10'; }
				     if (r_reward ==  10) { r_reward = '10'; }
				else if (r_reward == -10) { r_reward = '-10'; }
				
				/*
				console.log('start');
				console.log(trial.trial_type);
				console.log(trial.feedback_type);
				console.log(trial.user_choice);
				console.log(trial.reward);
				*/
				
				var ttm;
				if (trial.trial_top_message == null) {
					ttm = 'BLOCK: <span>' + trial.get_blocks().block_c + 
						'</span> , TRIAL: <span>' + trial.get_block().trial_c + '</span> !';
				} else {
					ttm = trial.trial_top_message + '<span>' + trial.get_block().trial_c + '</span>';
				}
				
				let src_fdbck = '';
				if (timeline == 4) {
					if (trial.source_feedback === true) {
						src_fdbck = 'True';
					} else if (trial.source_feedback === false) {
						src_fdbck = 'False';
					}
				}
				
				return '<div id="content">'+
					'<!-- <p id="block-c-trial-c" align="center">'+ttm+'</p> -->'+
					'<div id="block" class="act-div block">'+
						'<p class="source" align="center">'+
							'<!-- <img id="source" src="'+trial.get_block().data_source_img+'" /> -->'+
							'<p id="source-feedback" align="center">'+src_fdbck+'</p>'+
						'</p>'+
						'<div>'+
							'<div class="img" id="box-l">'+
								'<p align="center" id="star-img-l" class="act-img star">'+l_star+'</p>'+
								'<p align="center" class="act-img">'+
									'<img id="img-l" src="'+trial.div_left_data.src+'" />'+
								'</p>'+
								'<p align="center" id="reward-img-l" class="reward">'+l_reward+'</p>'+
							'</div>'+
							'<div class="img" id="box-r">'+
								'<p align="center" id="star-img-r" class="act-img star">'+r_star+'</p>'+
								'<p align="center" class="act-img">'+
									'<img id="img-r" src="'+trial.div_right_data.src+'" />'+
								'</p>'+
								'<p align="center" id="reward-img-r" class="reward">'+r_reward+'</p>'+
							'</div>'+
						'</div>'+
					'</div>'+
					'<p align="center" style="clear:both; padding:40px; color:green;">'+((trial.trial_down_message === null)? '' : trial.trial_down_message)+'</p>'+
				'</div>';
			}
			
			functions.replay = function(trial) {
				let type_1, type_2;
				if (trial.user_choice.type_left.img_type === 1) {
					type_1 = trial.user_choice.type_left;
					type_2 = trial.user_choice.type_right;
				} else {
					type_2 = trial.user_choice.type_left;
					type_1 = trial.user_choice.type_right;
				}
				
				let ran = Math.random();
				//reward
				if (trial.condition_type == 'gain') {
					trial.reward = (ran < trial.user_choice.type.chance)? 10 : 1;
				} else {
					trial.reward = (ran < trial.user_choice.type.chance)? -1 : -10;
				}
				//rewards 1 , 2
				if (trial.condition_type == 'gain') {
					trial.reward_1 = (ran < type_1.chance)? 10 : 1;
					trial.reward_2 = (ran < type_2.chance)? 10 : 1;
				} else {
					trial.reward_1 = (ran < type_1.chance)? -1 : -10;
					trial.reward_2 = (ran < type_2.chance)? -1 : -10;
				}
				//actual_outcomes
				if (trial.condition_type == 'gain') {
					trial.actual_outcomes = (ran < trial.user_choice.type.outcomes_chance)? 1 : 0;
				} else {
					// ****************
					trial.actual_outcomes = (ran < trial.user_choice.type.outcomes_chance)? 1 : 0;//0 : -1;
				}
				//source_feedback
				trial.source_feedback = trial.trial_type;
			}
			
			functions.f_bonus = function(blocks) {
				let bonus = 0;
				for (let k = 1; k <= blocks.timeline.length; k++) {
					for (let i = 1; i <= blocks.timeline[k-1].timeline[1].timeline.length; i++) {
						bonus+= blocks.get_trial(k, i).actual_outcomes;
					}
				}
				return bonus;
			}
			
		functions.save_csv = function(blocks, questions) {
				let t_body = 'Subject Id,Study Id,Session Id,Block,Trial,Choice,Reward,Reward1,Reward2,TrialType,FeedbackType,Left Image Src,Right Image Src,'+
					'Left Image Type,Right Image Type,Reaction,Condition,Actual Outcomes,Key Type,Condition Type,Catch Trial,Trial Fixation Time';
			
				for (let k = 1; k <= blocks.timeline.length; k++) {
					for (let i = 1; i <= blocks.timeline[k-1].timeline[1].timeline.length; i++) {
						t_body = t_body + '\n'+
						subject_id+','+study_id+','+session_id+','+
						k+','+
						i+','+
						blocks.get_trial(k, i).user_choice.choice+','+
						blocks.get_trial(k, i).reward+','+
						blocks.get_trial(k, i).reward_1+','+
						blocks.get_trial(k, i).reward_2+','+
						blocks.get_trial(k, i).trial_type+','+
						blocks.get_trial(k, i).feedback_type+','+
						functions.get_img_name(blocks.get_trial(k, i).div_left_data.src)+','+
						functions.get_img_name(blocks.get_trial(k, i).div_right_data.src)+','+
						blocks.get_trial(k, i).div_left_data.img_type+','+
						blocks.get_trial(k, i).div_right_data.img_type+','+
						blocks.get_trial(k, i).reaction_time+','+
						blocks.get_trial(k, i).condition+','+
						blocks.get_trial(k, i).actual_outcomes+','+
						blocks.get_trial(k, i).key_type+','+
						blocks.get_trial(k, i).condition_type+','+
						blocks.get_trial(k, i).catch_trial_response+','+
						blocks.get_trial(k, i).trial_fixation_time+','+
						'';
					}
				}
				t_body+= '\n';
			for (let f = 1; f <= 5; f++) {
					t_body+= 'question '+f+','+questions.responses[f]+'\n';
				}
				
				return t_body;
			}
			
			functions.save_table = function(blocks) {
				var t_body = '';
			
				for (var k = 1; k <= blocks.timeline.length; k++) {
					var tr_c = (k%2 == 0)? 'rgb(200, 255, 200)' : 'rgb(200, 200, 255)';
					for (var i = 1; i <= blocks.timeline[k-1].timeline[1].timeline.length; i++) {
						let b_color = (blocks.get_trial(k, i).reverse === true)? ' style="background-color:red;"' : '';
						t_body = t_body + '<tr style="background-color:'+tr_c+';">'+
						'<td id="subject-'+k+'-'+i+'"></td>'+
						'<td id="block-'+k+'-'+i+'" '+b_color+'>'+k+'</td>'+
						'<td id="trial-'+k+'-'+i+'" '+b_color+'>'+i+'</td>'+
						'<td id="choice-'+k+'-'+i+'">'+blocks.get_trial(k, i).user_choice.choice+'</td>'+
						'<td id="reward-'+k+'-'+i+'">'+blocks.get_trial(k, i).reward+'</td>'+
						'<td id="reward_1-'+k+'-'+i+'">'+blocks.get_trial(k, i).reward_1+'</td>'+
						'<td id="reward_2-'+k+'-'+i+'">'+blocks.get_trial(k, i).reward_2+'</td>'+
						'<td id="type-'+k+'-'+i+'">'+blocks.get_trial(k, i).trial_type+'</td>'+
						'<td id="feedback-type-'+k+'-'+i+'">'+blocks.get_trial(k, i).feedback_type+'</td>'+
						'<td id="left-img-src-'+k+'-'+i+'">'+functions.get_img_name(blocks.get_trial(k, i).div_left_data.src)+'</td>'+
						'<td id="right-img-src-'+k+'-'+i+'">'+functions.get_img_name(blocks.get_trial(k, i).div_right_data.src)+'</td>'+
						'<td id="left-img-type-'+k+'-'+i+'">'+blocks.get_trial(k, i).div_left_data.img_type+'</td>'+
						'<td id="right-img-type-'+k+'-'+i+'">'+blocks.get_trial(k, i).div_right_data.img_type+'</td>'+
						'<td id="reaction-time-'+k+'-'+i+'">'+blocks.get_trial(k, i).reaction_time+'</td>'+
						'<td id="condition-'+k+'-'+i+'">'+blocks.get_trial(k, i).condition+'</td>'+
						'<td id="actual-outcomes-'+k+'-'+i+'">'+blocks.get_trial(k, i).actual_outcomes+'</td>'+
						'<td id="key-type-'+k+'-'+i+'">'+blocks.get_trial(k, i).key_type+'</td>'+
						'<td id="condition-type-'+k+'-'+i+'">'+blocks.get_trial(k, i).condition_type+'</td>'+
						'<td id="catch-trial-'+k+'-'+i+'">'+blocks.get_trial(k, i).catch_trial_response+'</td>'+
						'<td id="trial-fixation-time-'+k+'-'+i+'">'+blocks.get_trial(k, i).trial_fixation_time+'</td>'+
						'</tr>';
					}
				}
				
				var table = '<div id="console" class="act-div">'+
								'<div style="direction:ltr; padding:20px;">'+
									'<table id="data-table">'+
										'<thead>'+
											'<tr>'+
												'<th>Subject</th>'+
												'<th>Block</th>'+
												'<th>Trial</th>'+
												'<th>Choice</th>'+
												'<th>Reward</th>'+
												'<th>Reward 1</th>'+
												'<th>Reward 2</th>'+
												'<th>Trial Type</th>'+
												'<th>Feedback Type</th>'+
												'<th>Left Image Src</th>'+
												'<th>Right Image Src</th>'+
												'<th>Left Image Type</th>'+
												'<th>Right Image Type</th>'+
												'<th>Reaction Time</th>'+
												'<th>Condition</th>'+
												'<th>Actual Outcomes</th>'+
												'<th>Key Type</th>'+
												'<th>Condition Type</th>'+
												'<th>Catch Trial</th>'+
												'<th>Trial Fixation Time</th>'+
											'</tr>'+
										'</thead>'+
										'<tbody id="table-body">'+t_body+'</tbody>'+
									'</table>'+
								'</div>'+
							'</div>';
				
				functions.save_data_excel(table, 'task-data-save');
			}
			
			functions.save_data_excel = function(data, filename = '') {
				var downloadLink;
				var dataType = 'application/vnd.ms-excel';
				var tableHTML = data.replace(/ /g, '%20');
				// Specify file name
				filename = filename? filename+'.xls' : 'excel_data.xls';
				// Create download link element
				downloadLink = document.createElement("a");
				document.body.appendChild(downloadLink);
				
				if (navigator.msSaveOrOpenBlob) {
					var blob = new Blob(['\ufeff', tableHTML], {
						type: dataType
					});
					navigator.msSaveOrOpenBlob(blob, filename);
				} else {
					// Create a link to the file
					downloadLink.href = 'data:' + dataType + ', ' + tableHTML;
					// Setting the file name
					downloadLink.download = filename;
					//triggering the function
					downloadLink.click();
				}
			}
			
			functions.sort_random = function(input) {
				for (var i = 0; i < input.length; i++) {
					if (Math.random() < 0.5) {
						var ran = Math.floor(Math.random()*input.length);
						var x = input[i];
						input[i] = input[ran];
						input[ran] = x;
					}
				}
				
				return input;
			}
			
			functions.set_half_true_1 = function(size, type = 'b') {
				var block_array = new Array(size);
				var s_true = 0, s_false = 0;
				for (var i = 0; i < block_array.length; i++) {
					var ran = Math.random();
					if (((ran < 0.5) && (s_false < block_array.length/2)) || (s_true >= block_array.length/2)) {
						block_array[i] = (type == 'b')? false : 0;
						s_false++;
					} else if (((ran >= 0.5) && (s_true < block_array.length/2)) || (s_false >= block_array.length/2)) {
						block_array[i] = (type == 'b')? true : 1;
						s_true++;
					}
				}
				
				return block_array;
			}
			
			functions.get_img_name = function(src) {
				var end_point = src.lastIndexOf(".");
				var end_slash = src.lastIndexOf("/");
				
				return src.slice(end_slash+1, end_point);
			}
			
			functions.in_array = function(in_, array_) {
				for (let i = 0; i < array_.length; i++) {
					if (in_ == array_[i]) { return true; }
				}
				return false;
			}
			
			
			
			///////////////////////////////////////////////////////////////////////////////////////////////////////////
			function exportTableToExcel(tableID, filename = '') {
				var downloadLink;
				var dataType = 'application/vnd.ms-excel';
				var tableSelect = document.getElementById(tableID);
				var tableHTML = tableSelect.outerHTML.replace(/ /g, '%20');
				// Specify file name
				filename = filename? filename+'.xls' : 'excel_data.xls';
				// Create download link element
				downloadLink = document.createElement("a");
				document.body.appendChild(downloadLink);
				
				if (navigator.msSaveOrOpenBlob) {
					var blob = new Blob(['\ufeff', tableHTML], {
						type: dataType
					});
					navigator.msSaveOrOpenBlob(blob, filename);
				} else {
					// Create a link to the file
					downloadLink.href = 'data:' + dataType + ', ' + tableHTML;
					// Setting the file name
					downloadLink.download = filename;
					//triggering the function
					downloadLink.click();
				}
			}
			
