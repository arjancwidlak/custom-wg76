package WebGUI::i18n::English::Asset_BuzzCollector;  

use strict; 

our $I18N = {
    'assetName' => {
        message     => q|BuzzCollector|,
        lastUpdated => 0,
    }, 

    'max items per type label' => {
        message     => q|Maximum number of items per type|,
        lastUpdated => 0,
        context     => q|Label for asset edit screen|,
    },
    
    'max items per type description' => {
        message     => q|Select the maximum number of items per type that should be displayed.|,
        lastUpdated => 0,
        context     => q|Hover help for asset edit screen|,
    },

    'max item age label' => {
        message     => q|Maximum item age|,
        lastUpdated => 0,
        context     => q|Label for asset edit screen|,
    },

    'max item age description' => {
        message     => q|Select the maximum age for Buzz Collector items.|,
        lastUpdated => 0,
        context     => q|Hover help for asset edit screen|,
    },

    'sort label' => {
        message     => q|Sort:|,
        lastUpdated => 0,
        context     => q|Label for asset edit screen|,
    },

    'sort description' => {
        message     => q|Select the way items should be sorted.|,
        lastUpdated => 0,
        context     => q|Hover help for asset edit screen|,
    },

    'template description' => {
        message     => q|Select a template to be used to display the BuzzCollector.|,
        lastUpdated => 0,
        context     => q|Hover help for asset edit screen|,
    },

    'template label' => {
        message     => q|BuzzCollector Template|,
        lastUpdated => 0,
        context     => q|Label for asset edit screen|,
    },

    'itemType description' => {
        message     => q|The type of the item that is being added or edited.|,
        lastUpdated => 0,
        context     => q|Hover help for asset edit screen|,
    },

    'itemType label' => {
        message     => q|Item Type|,
        lastUpdated => 0,
        context     => q|Label for asset edit screen|,
    },

    'userlist description' => {
        message     => q|Select the UserList which 'include/exclude group' settings should be used.|,
        lastUpdated => 0,
        context     => q|Hover help for item edit screen|,
    },

    'userlist label' => {
        message     => q|UserList|,
        lastUpdated => 0,
        context     => q|Label for item edit screen|,
    },

    'add item label' => {
        lastUpdated => 0,
        message     => q|Add Item|,
    },

    'list items title' => {
        lastUpdated => 0,
        message     => q|Item List|,
    },

    'delete item confirm message' => {
        message     => q|Are you certain you wish to delete this item?|,
        lastUpdated => 0,
    },

    'edit item title' => {
        lastUpdated => 0,
        message => q|Edit/Add Item|
    },

    'userlist user label' => {
        message     => q|UserList User|,
        lastUpdated => 0,
    },

    'collaboration label' => {
        message     => q|Collaboration System|,
        lastUpdated => 0,
    },

    'date label' => {
        message     => q|Date|,
        lastUpdated => 0,
    },

    'collaboration description' => {
        message     => q|Select the Collaboration System from which threads/replies should be displayed.|,
        lastUpdated => 0,
    },

    'includeAssets label' => {
        message     => q|Inlude Threads/Replies|,
        lastUpdated => 0,
    },

    'includeAssets description' => {
        message     => q|Display only threads or replies or both.|,
        lastUpdated => 0,
    },

    'includeAssets threads label' => {
        message     => q|Threads|,
        lastUpdated => 0,
    },

    'includeAssets replies label' => {
        message     => q|Replies|,
        lastUpdated => 0,
    },

    'includeAssets both label' => {
        message     => q|Both|,
        lastUpdated => 0,
    },

    'collaboration post label' => {
        message     => q|Post or Thread from Collaboration|,
        lastUpdated => 0,
    },

    'buzzcollector template help title' => {
        message     => q|BuzzCollector Template|,
        lastUpdated => 0,
    },

    'item_loop' => {
        message     => q|A loop containing BuzzCollector items.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    'itemType' => {
        message     => q|The item type of this BuzzCollector item.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    'is[ITEMTYPE]' => {
        message     => q|A boolean indicating if this BuzzCollector item is a [ITEMTYPE], example &lt;tmpl_var
isPost&gt;.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    'dateCreated' => {
        message     => q|The date this item was created in epoch format.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    'dateCreatedHuman' => {
        message     => q|The date this item was created in human readable format.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    '[POST_PROPERTY]' => {
        message     => q|A standard Post Asset property, example &lt;tmpl_var title&gt;. Only available if this BuzzCollector item is a Post.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    'userId' => {
        message     => q|A userId, only available if this BuzzCollector item is a user.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    'user_[PROFILE FIELDNAME]' => {
        message     => q|The value of [PROFILE FIELDNAME] in this users profile, only available if this BuzzCollector item is a user. Example &lt;tmpl_var user_firstName&gt; |,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    'sender_[PROFILE FIELDNAME]' => {
        message     => q|The value of [PROFILE FIELDNAME] in the sender's profile, only available if this BuzzCollector item is a Date, example: &lt;tmpl_var sender_firstName&gt;.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    'recipient_[PROFILE FIELDNAME]' => {
        message     => q|The value of [PROFILE FIELDNAME] in the recipient's profile, only available if this BuzzCollector item is a Date, example: &lt;tmpl_var sender_firstName&gt;.|,
        lastUpdated => 0,
        context     => q|Template help description|,
    },

    '' => {
        message     => q||,
        lastUpdated => 0,
    },

};

1;
#vim:ft=perl
