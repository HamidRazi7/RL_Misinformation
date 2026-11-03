/**
 * jspsych-consent-form-p2

 **/

jsPsych.plugins['consent-form-p2'] = (function() {
  var plugin = {};

  plugin.info = {
    name: 'consent-form-p2',
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
    var plugin_id_name = "jspsych-survey-consent-form-p2";
    var plugin_id_selector = '#' + plugin_id_name;
    var _join = function( /*args*/ ) {
      var arr = Array.prototype.slice.call(arguments, _join.length);
      return arr.join(separator = '-');
    }

    // Initialize HTML
    var html = "";
	
	html += '<style>'+
				'form p {font-size: 0.85rem; text-align: left; padding-left: 50px; padding-right: 50px;}'+
				'form div {text-align: left; padding-left: 20px;}'+
			'</style>';

    // Add factory machine parts (back).
    html += '<div style="padding: 15px;">';

    // Initialize form element
    html += '<form id="jspsych-survey-multi-choice-form">';
	
	html += '<h3>Decision Making</h3>'+
	'<p></p>'+
	'<b>PARTICIPANT INFORMATION SHEET</b>'+'<br>'+
	'<span>Ethics Approval Reference: <b>Approved on February 5<sup>th</sup> 2024<b></span>'+
	'<p></p>'+
	'<p>Thank you for your interest in this study. Before you decide whether to take part, please read the following information carefully </p>'+
	'<div><b>What is this research looking at?</b></div>'+
	'<p>This study explores how people learn the value of different options in their environment and use these values to make choices. By understanding these processes that are fundamental to decision making, we hope to highlight how and why decision making exhibits inconsistencies in certain cases and how the processes involved relate to clinical pathologies.</p>'+
	'<div><b>Why have I been invited to take part? </b></div>'+
	'<p>You have been invited because you responded to an advert for this study. To take part, you need to be between 18 and 40 years old. You also need to have normal vision or vision corrected through glasses or contact lenses. </p>'+
	'<div><b>Do I have to take part?</b></div>'+
	'<p>No. It is up to you to decide whether you want to take part or not. Please read this information sheet to help you decide. You can also ask questions about the study before deciding by emailing the principal researcher(Hamid Razi: H.Razi@uea.ac.uk). If you decide to take part, you are free to withdraw at any time without giving a reason. Since this is an online study that takes place in an internet browser on your computer, if you want to withdraw from the study simply close the internet browser running the study and the study will automatically end. Please note that we are only able to reimburse participants who complete a study.</p>'+
	'<div><b>What will happen if I agree to take part?	</b></div>'+
	'<p>This study will last a maximum of 1 hour and will take place online. You will be presented with different options (e.g., different pictures or different symbols) and asked to choose between them. After you choose an option, you will receive feedback about some or all of the options. </p>'+
	'<p>You will be reimbursed for your time in the study with three credits. In addition, you will be paid a bonus up to £4 based on your performance (the more points you win and the less points you lose, the higher your bonus will be).  </p>'+
	'<div><b>Will it help me if I take part?</b></div>'+
	'<p>There will be no direct benefit to you from taking part in this research. </p>'+
	'<div><b>How will you store the information that I give you?</b></div>'+
	'<p>All information which you provide during the study will be stored in accordance with the 2018 General Data Protection Regulation and kept strictly confidential. The chief investigator will be the custodian of the anonymous research data. We will not collect or store any identifiable data. All anonymized data and results will be stored indefinitely in order to comply with open practice standards. The electronic data will be stored on the university secure Research Storage Infrastructure, based on IBM enterprise grade Storage Area Network (SAN) hardware housed in secure, environmentally controlled and monitored data centres. Data will be regularly and automatically backed up to tape with on-site and off-site copies. </p>'+
	'<div><b>How will the data be used?</b></div>'+
	'<p>Findings and anonymised research results that arise from the data will potentially be presented at conferences and published in peer-reviewed scientific journals. Before that time we may make the results available as a preprint on bioRxiv (<a href="https://www.biorxiv.org">https://www.biorxiv.org</a>) where new scientific results are often first reported. The anonymized data may be made available to the worldwide scientific community by hosting it on a public website (e.g., OSF or GitHub) to promote transparency in science and to facilitate its potential use in future research by other research groups.</p>'+
	'<div><b>What happens if I agree to take part, but change my mind later?</b></div>'+
	'<p>You have the right to withdraw and ask us to not use your data. However, please note that anonymity may make it very difficult or impossible to withdraw data retroactively from the study after completing all of an online session.</p>'+
	'<div><b>How do I know that this research is safe for me to take part in?</b></div>'+
	'<p>Although every reasonable effort will be taken to prevent breaches of confidentiality and protect the data we collect, confidentiality during actual Internet communication procedures cannot be guaranteed. However, we will take steps to mitigate as much of this risk as possible by only having access to fully anonymized data which is stored on password protected servers at the University of East Anglia. We will not collect or store any data that can identify you (e.g., your email address or IP address).</p>'+
	'<p>This research has been approved by an ethics committee on February 5<sup>th</sup>, 2024. All research in the University is looked at by an independent group of people, called a Research Ethics Committee, to protect your safety, rights, wellbeing and dignity. This research was approved by the Psychology Research Ethics Committee on February 5<sup>th</sup> 2024. </p>'+
	'<div><b>Contact details</b></div>'+
	'<p>If you have a concern about any aspect of this study, please speak to the Hamid Razi (H.Razi@uea.ac.uk) or their supervisor, Dr Thomas Sambrook (T.Sambrook@uea.ac.uk), and we will do our best to answer your query. If you remain unhappy or wish to make a formal complaint, please contact the Psychology Ethics Committee at the University of East Anglia who will seek to resolve the matter as soon as possible</p>'+

  '<p> Hamid Razi (H.Razi@uea.ac.uk),  Dr Thomas Sambrook (  T.Sambrook@uea.ac.uk),   School of Psychology Ethics Committee (ethics.psychology@uea.ac.uk),   Head of School Professor Neil Cooper (neil.cooper@uea.ac.uk)</p>'
    


	
    // add submit button
    html += '<input type="submit" id="'+plugin_id_name+'-next" class="'+plugin_id_name+' jspsych-btn"' + (trial.button_label ? ' value="'+trial.button_label + '"': '') + '"></input>';

    // End HTML
    html += '</form>';
    html += '</div>';

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
      // clear html
      display_element.innerHTML += '';
      // next trial
      jsPsych.finishTrial();
    });

  };

  return plugin;
})();
