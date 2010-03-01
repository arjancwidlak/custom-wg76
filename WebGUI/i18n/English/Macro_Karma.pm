package WebGUI::i18n::English::Macro_Karma;

our $I18N = {

    'macroName' => {
        message => q|Karma|,
        lastUpdated => 1162941955,
    },

    'karma message' => {
        message => q|You have %d karma.|,
        lastUpdated => 1162941996,
    },

    'karma title' => {
        message => q|Karma Macro|,
        lastUpdated => 1162941998,
    },

	'karma body' => {
		message => q|
<p><b>&#94;Karma(<i>text message</i>);</b><br />
Shows the user how much karma they have.  The message can be customized via the
optional <i>text message</i> parameter to the macro.  The message should contain
this key "%d" to show where the amount of karma should be placed.
</p>
<p>The default <i>text message</i> is:<br />
You have %d karma.</p>
|,
		lastUpdated => 1162942011,
	},
};

1;
