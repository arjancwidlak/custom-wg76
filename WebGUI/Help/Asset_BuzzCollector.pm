package WebGUI::Help::Asset_BuzzCollector;
use strict;

our $HELP = {
    'buzzcollector template' => {
        title     => 'buzzcollector template help title',
        body      => '',
        isa    => [
            {   namespace => "Asset_Wobject",
                tag       => "wobject template variables",
            },
            {   namespace => "Asset_Template",
                tag       => "template variables",
            },
            {   tag       => 'asset template asset variables',
                namespace => 'Asset'
            },
        ],
        variables => [
            {   'name'      => 'item_loop',
                'variables' => [
                    { 'name' => 'itemType' },
                    { 'name' => 'is[ITEMTYPE]' },
                    { 'name' => 'dateCreated' },
                    { 'name' => 'dateCreatedHuman' },
                    { 'name' => '[POST_PROPERTY]' },
                    { 'name' => 'userId' },
                    { 'name' => 'user_[PROFILE FIELDNAME]' },
                    { 'name' => 'sender_[PROFILE FIELDNAME]' },
                    { 'name' => 'recipient_[PROFILE FIELDNAME]' },
                ]
            },
        ],
    },
};

1;
