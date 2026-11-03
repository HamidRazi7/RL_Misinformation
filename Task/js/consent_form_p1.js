/**
 * jspsych-consent-form-p1
 * 
 * A plugin for implementing standardized informed consent procedures in online research
 

 **/

jsPsych.plugins['consent-form-p1'] = (function() {
	var plugin = {};
  
	plugin.info = {
	  name: 'consent-form-p1',
	  description: 'Implements standardized informed consent procedures for online research studies',
	  parameters: {
		button_label: {
		  type: jsPsych.plugins.parameterType.STRING,
		  pretty_name: 'Consent button label',
		  default: 'I Consent to Participate',
		  description: 'Text displayed on the consent submission button'
		}
	  }
	}
  
	plugin.trial = function(display_element, trial) {
  
	  // Configuration parameters
	  const plugin_id_name = "jspsych-survey-consent-form-p1";
	  const plugin_id_selector = '#' + plugin_id_name;
  
	  // Utility functions
	  const _join = function( /*args*/ ) {
		var arr = Array.prototype.slice.call(arguments, _join.length);
		return arr.join(separator = '-');
	  }
  
	  // Initialize consent interface
	  let html = "";
	  
	  // Define styling for consent form
	  html += `
		<style>
		  .consent-table td {
			border: 1px solid #000;
			padding: 15px;
			text-align: left;
			vertical-align: top;
		  }
		  .consent-header {
			text-align: center;
			margin-bottom: 2em;
		  }
		  .consent-checkbox {
			width: 20px;
			height: 20px;
		  }
		</style>
	  `;
  
	  // Construct consent form header
	  html += `
		<div class="consent-form-container">
		  <div class="consent-header">
			<h1>Informed Consent Document</h1>
			<h2>Research Study on Information Processing and Decision Making</h2>
			<h3>Principal Investigators: [Names and Affiliations]</h3>
		  </div>
	  `;
  
	  // Initialize consent checklist
	  html += '<form id="jspsych-survey-multi-choice-form">';
	  
	  // Define consent items
	  const consentItems = [
		"I have read and understand the participant information sheet.",
		"I have had the opportunity to ask questions about the study and received satisfactory answers.",
		"I understand my right to withdraw from the study at any point without penalty.",
		"I acknowledge this study has received institutional ethics committee approval.",
		"I understand how this research will be documented and published.",
		"I understand that no personally identifiable information will be collected.",
		"I consent to my anonymized data being stored in open access archives for research purposes.",
		"I understand the procedure for raising concerns or complaints.",
		"I voluntarily agree to participate in this research study."
	  ];
  
	  // Generate consent table
	  html += '<table class="consent-table"><tbody>';
	  consentItems.forEach((item, index) => {
		html += `
		  <tr>
			<td><input type="checkbox" id="consent-form-p1-c${index + 1}" class="consent-checkbox" required /></td>
			<td><label for="consent-form-p1-c${index + 1}">${item}</label></td>
		  </tr>
		`;
	  });
	  html += '</tbody></table>';
  
	  // Add submission interface
	  html += `
		<div style="padding: 15px; text-align: center;">
		  <input type="submit" 
				 id="${plugin_id_name}-next" 
				 class="${plugin_id_name} jspsych-btn" 
				 value="${trial.button_label}"
				 style="font-size: 1.2em; padding: 10px 20px;" />
		</div>
	  `;
  
	  // Finalize HTML structure
	  html += '</form></div>';
  
	  // Render consent interface
	  display_element.innerHTML = html;
  
	  // Implement consent validation
	  document.querySelector('form').addEventListener('submit', function(event) {
		event.preventDefault();
		
		// Validate all checkboxes
		const checkboxes = Array.from({ length: 9 }, (_, i) => 
		  document.querySelector(`#consent-form-p1-c${i + 1}`).checked
		);
  
		if (checkboxes.every(checked => checked)) {
		  // Record consent timestamp
		  const consentTimestamp = new Date().toISOString();
		  
		  // Clear interface and proceed
		  display_element.innerHTML = '';
		  jsPsych.finishTrial({
			consent_granted: true,
			consent_timestamp: consentTimestamp
		  });
		} else {
		  alert('Please review and acknowledge all consent items to proceed.');
		  return false;
		}
	  });
	};
  
	return plugin;
  })();