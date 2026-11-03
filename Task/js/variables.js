	/**/
	let subject = 1;
	
    var fixation_cross_times = [
		[3900, 4000, 4100],

	];
	var fixation_cross_1_time = 1;
	var fixation_cross_2_time = 1;
	
	//practice trials 
	let i_images_1_2 = [
		functions.sort_random(['./img/e.png', './img/ep.png']), 
		functions.sort_random(['./img/f.png', './img/fp.png']), 
		functions.sort_random(['./img/h.png', './img/hp.png']), 
		functions.sort_random(['./img/j.png', './img/jp.png'])
	];
	i_images_1_2 = functions.sort_random(i_images_1_2);
	
	let i_con1_img1_img2 = i_images_1_2[0];
	let i_con2_img1_img2 = i_images_1_2[1];
	let i_con3_img1_img2 = i_images_1_2[2];
	let i_con4_img1_img2 = i_images_1_2[3];
	
	let i_blocks_trials = [
		{
			images_data: functions.sort_random([
				{
					img_1:{src: i_con1_img1_img2[0], t_true:0.8, t_false:0.5}, //define the probabilities of each option for each trial type
					img_2:{src: i_con1_img1_img2[1], t_true:0.2, t_false:0.5},
					size:6, //number of practice trials for this pair
					name:1, //name of the pair
					block_middle:null, //reserved for cases where probabilities are changed half-way through
					condition_type:'gain',// gain loss
				}, 
				{
					img_1:{src: i_con2_img1_img2[0], t_true:0.8, t_false:0.5}, 
					img_2:{src: i_con2_img1_img2[1], t_true:0.2, t_false:0.5},
					size:6,
					name:2,
					block_middle:null,
					condition_type:'loss',// gain loss
				}, 
			]),
			fixation_cross_times: fixation_cross_times[0],
			interrupts: [],
		},
	];

	//main task trials
	
	let images_1_2 = [
		functions.sort_random(['./img/a.png', './img/ap.png']), 
		functions.sort_random(['./img/b.png', './img/bp.png']), 
		functions.sort_random(['./img/c.png', './img/cp.png']), 
		functions.sort_random(['./img/d.png', './img/dp.png']),
		functions.sort_random(['./img/m.png', './img/mp.png']),
		functions.sort_random(['./img/n.png', './img/np.png']),
		functions.sort_random(['./img/o.png', './img/op.png']),
		functions.sort_random(['./img/p.png', './img/pp.png'])
	];
	images_1_2 = functions.sort_random(images_1_2);
	
	let con1_img1_img2 = images_1_2[0];
	let con2_img1_img2 = images_1_2[1];
	let con3_img1_img2 = images_1_2[2];
	let con4_img1_img2 = images_1_2[3];
	let con5_img1_img2 = images_1_2[4];
	let con6_img1_img2 = images_1_2[5];
	let con7_img1_img2 = images_1_2[6];
	let con8_img1_img2 = images_1_2[7];
	
	conditions = [
		{
			img_1:{src: con1_img1_img2[0], t_true:0.8, t_false:0.5}, 
			img_2:{src: con1_img1_img2[1], t_true:0.2, t_false:0.5},
			size:4, // number of trials
			name:1, // name of the pair
			block_middle:null, //reserved for cases where probabilities are changed half-way through
			condition_type:'gain',// gain loss
		}, 
		{
			img_1:{src: con2_img1_img2[0], t_true:0.5, t_false:0.8}, 
			img_2:{src: con2_img1_img2[1], t_true:0.5, t_false:0.2},
			size:4,
			name:2,
			block_middle:null,
			condition_type:'gain',// gain loss
		},
		{
			img_1:{src: con3_img1_img2[0], t_true:0.8, t_false:0.5}, 
			img_2:{src: con3_img1_img2[1], t_true:0.2, t_false:0.5},
			size:4,
			name:3,
			block_middle:null,
			condition_type:'loss',// gain loss
		},
		{
			img_1:{src: con4_img1_img2[0], t_true:0.5, t_false:0.8}, 
			img_2:{src: con4_img1_img2[1], t_true:0.5, t_false:0.2},
			size:4,
			name:4,
			block_middle:null,
			condition_type:'loss',// gain loss
		},
		
		
	];
	//conditions = functions.sort_random(conditions);
	
	let task_blocks_trials = [
		{
			images_data: [
				conditions[0],
				conditions[1],
				conditions[2],
				conditions[3]
			],
			fixation_cross_times: [],
            interrupts: [80], //break half-way through 
		},
	
	];
	for (let p = 0; p < task_blocks_trials.length; p++) {
		task_blocks_trials[p].fixation_cross_times = fixation_cross_times[p];
	}
	
	var prolific_code = 'C1CBIOV7';
	
	var choice_to_feedback_time = 500; //choice confirmation
	var feedback_to_next_time = 1000; //outcome duration
	var trial_timeline3_to_timeline4_time = 1000; //accuracy duration
	
	var i_catch_trial_size = 2; //number of catch trials in the practice trials
	var task_catch_trial_size = 1; //number of catch trials in the main task
	
	//****************************************************************************************
	
	//------------------------------------//
	// Define images for preloading.
	//------------------------------------//
	preload_images = [

		
		'./img/a.png',
		'./img/ap.png',
		'./img/b.png',
		'./img/bp.png',
		'./img/c.png',
		'./img/cp.png',
		'./img/d.png',
		'./img/dp.png',
		
		'./img/e.png',
		'./img/ep.png',
		'./img/f.png',
		'./img/fp.png',
		'./img/h.png',
		'./img/hp.png',
		'./img/j.png',
		'./img/jp.png',
		
		'./img/m.png',
		'./img/mp.png',
		'./img/n.png',
		'./img/np.png',
		'./img/o.png',
		'./img/op.png',
		'./img/p.png',
		'./img/pp.png',
		

		
		'./img/star.png',
		
		'./img/d_p_2.png',
		
		'./img/fixation-cross.png',
		'./img/div-white.png',
		'./img/div-yellow.png',
	];
	
	//******************************************************************************************
	
	//// images_data = functions.sort_random(images_data);
	
