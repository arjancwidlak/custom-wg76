/*
    Config: JSON string with following structure:

    {
        FORM_ID_1 : {
            ELEMENT_NAME_1 : {
                type            : INPUT_EX_TYPE,
                paramOptions    : {
                    INPUT_EX_OPTION_1 : VALUE_1,
                    INPUT_EX_OPTION_2 : VALUE_2,
                    ...
                }
            },
            ELEMENT_NAME_2 : {
                type            : INPUT_EX_TYPE,
                paramOptions    : {
                    ...
                }
            },
            ...
        },
        FORM_ID_2 : {
            ...
        },
        ...
    }
*/

InputExAttacher = function ( config, inputExBase, yuiBase, customModule ) {
    this.configuration  = config;
    this.inputExBase    = inputExBase;
    this.yuiBase        = yuiBase;
    this.customModule   = customModule;
    this.formElements   = [];

    this.initialise();
}


InputExAttacher.prototype.getElements = function ( form ) {
    for ( var i = 0; i < this.formElements.length; i++ ) {
        if ( this.formElements[ i ].form === form ) {
            return this.formElements[ i ].elements;
        }
    }

    var elements = [ ];
    this.formElements.push( {
        'form'      : form,
        'elements'  : elements
    } );

    return elements;
}

//-----------------------------------------------------------------
// Replaces the html form elements with their inputEx counterparts
InputExAttacher.prototype.replaceElements = function ( a, b, c, d, e ) {
    for ( var id in this.configuration ) {
        var container = document.getElementById( id );
        var forms = container.getElementsByTagName( 'FORM' );

        for ( var i = 0; i < forms.length; i++ ) {
            var form = forms[i];

            var elements = this.getElements( form );

            // Add a submit handler
//            YAHOO.util.Event.addListener( form, 'submit', this.validateForm, this, true );

            for ( var field in this.configuration[ id ] ) {
                var fieldDefinition = this.configuration[ id ][ field ];

                // Find element with given name
                var element = form[ field ]; //YAHOO.util.Dom.getElementsBy( function ( el ) { return el.name == field }, '*', form )[0];

                if (!fieldDefinition.inputParams) {
                    fieldDefinition.inputParams = {};
                }

                fieldDefinition.inputParams.name      = field;
                fieldDefinition.inputParams.value     = element.value;

                // Add the inputEx field.
                var control = YAHOO.inputEx( fieldDefinition );
                elements.push( control );

                if ( fieldDefinition.inputParams.hideMsgOnLoad ) {
                    control.displayMessage( '' );
                }

                element.parentNode.replaceChild( control.getEl(), element );
            }
        }
    }
}

//-----------------------------------------------------------------
InputExAttacher.prototype.validateForm = function ( e ) {
    var form        = YAHOO.util.Event.getTarget( e );
    var elements    = this.getElements( form );

    for (var i = 0; i < elements.length; i++ ) {
        if ( elements[i].validate() ) {
            console.log( 'valid' );
        }
        else {
            console.log( 'NOT valid' );
        }
    }

    YAHOO.util.Event.stopEvent( e );
}

InputExAttacher.prototype.validate = function ( form ) {
    var valid       = true;
    var elements    = this.getElements( form );

    for (var i = 0; i < elements.length; i++ ) {
        if ( elements[i].validate() ) {
            elements[i].displayMessage( '' );
        }
        else {
            valid = false;
            
            //elements[i].displayMessage( elements[i].getStateString( elements[i].getState() ) );
            var showMsgState = elements[i].options.showMsg;
//            if ( this.showMsgOnValidate ) {
                elements[i].options.showMsg = true;
//            }
            elements[i].setClassFromState();
            elements[i].options.showMsg = showMsgState;
        }
    } 

    return valid;
}

//-----------------------------------------------------------------
// Loads the required inputEx modules using the YUI loader.
//
InputExAttacher.prototype.initialise = function () {
        // Fetch the list of required inputEx modules 
        var modules = this.requiredModules();

        var loader = new YAHOO.util.YUILoader( {
            scope           : this,
            loadOptional    : true,
            base            : this.yuiBase ? this.yuiBase : null,
            onFailure       : function () { alert( 'InputExAttacher: Failed to load required modules.' ) },
            onSuccess       : this.replaceElements,
            onTimeout       : function () { alert( 'InputExAttacher: Loading required modules timed out.') },
            ignore          : [ 'reset-fonts' ]
        } );

        YAHOO.addInputExModules( loader, this.inputExBase ); 
        
        // Handle custom modules
        if (this.customModule) {
            loader.addModule( {
                name        : 'inputex-custom',
                varName     : 'inputEx.customModule',
                type        : 'js',
                fullpath    : this.customModule,
                requires    : modules.slice()          // Create copy of array
            } );

            modules.push( 'inputex-custom' );
        }

        loader.require( modules )
        loader.insert();

        this.ld = loader; 
}

//-----------------------------------------------------------------
// Returns an array containing the inputEx modules required for the configuration. 
//
// WARNING: Doesn't work for all fields!
//

InputExAttacher.prototype.requiredModules = function () {
    var fieldTypes = { 'string' : 1 };

    for (var container in this.configuration) {
        for (var field in this.configuration[ container ]) {
            var fieldType = this.configuration[ container ][ field ].type;
            fieldTypes[ fieldType ] = 1;
        }
    }

    var loadModules = [];
    for (var key in fieldTypes) {
        if ( key === 'text' ) {
            key = 'inputex-textarea';
        }
        else {
            key = 'inputex-' + key + 'field';
        }

        loadModules.push( key );
    }

    return loadModules; 
}


