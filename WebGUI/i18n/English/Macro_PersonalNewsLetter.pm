package WebGUI::i18n::English::Macro_PersonalNewsLetter;
use strict;

our $I18N = {

	'startTime label' => {
		message => q|Send at:|,
		lastUpdated => 0,
	},

	'startTime description' => {
		message => q|Select at what time sending the newsletter should begin.|,
		lastUpdated => 0,
	},

	'timeBetweenNewsLetters label' => {
		message => q|Wait time between Newsletters|,
		lastUpdated => 0,
	},

	'timeBetweenNewsLetters description' => {
		message => q|Select the number of seconds to wait between sending each NewsLetter.|,
		lastUpdated => 0
	},

	'sending in progress message' => {
		message => q|Sending this newsletter is in progress since |,
		lastUpdated => 0
	},

    'in queue message' => {
        message => q| newsletters are queued to be generated and sent.|,
        lastUpdated => 0
    },

    'in mailQueue message' => {
        message => q| emails are queued to be sent (including other emails).|,
        lastUpdated => 0
    },

    'activity in progress message' => {
        message => q|This activity is currently active: |,
        lastUpdated => 0
    },

};

1;
