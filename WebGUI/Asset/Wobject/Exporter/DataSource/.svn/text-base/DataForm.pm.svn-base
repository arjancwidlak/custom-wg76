package WebGUI::Asset::Wobject::Exporter::DataSource::DataForm;

use strict;

use base qw{ WebGUI::Asset::Wobject::Exporter::DataSource };

sub crud_definition {
    my $class   = shift;
    my $session = shift;

    my $definition = $class->SUPER::crud_definition( $session );

    $definition->{ options }->{ dataFormId } = {
        fieldType   => 'asset',
        label       => 'DataForm to export',
        class       => $class->getAssetClass( $session ),
    };

    return $definition;

}

sub getAssetClass {
    return 'WebGUI::Asset::Wobject::DataForm';
}

sub getSql {
    my $self    = shift;
    my $alias   = shift;
    my $dbh     = $self->session->db->dbh;

    my $columns = [ qw{ DataForm_entryId } ];
    my $table   = 'DataForm_entry';
    my $join    = 'userId';
    my $where   = $dbh->quote_identifier( $alias, 'assetId' ) .'='. $dbh->quote( $self->getOption('dataFormId') );

    return ($columns, $table, $join, $where);
}

sub getFields {
    my $self        = shift;
    my $dataForm    = $self->getDataForm;
    return $dataForm->getFieldOrder;
}

sub getFieldLabels {
    my $self    = shift;

    my $dataForm = $self->getDataForm;

    my @labels = map { $dataForm->getFieldConfig( $_ )->{label} } @{ $self->getFields };

    return @labels;
}

sub getColumnCount {
    my $self    = shift;

    return 1; # scalar @{ $self->getFields };
}

sub getDataForm {
    my $self    = shift;
    my $session = $self->session;

    my $dataForm = eval { WebGUI::Asset->newByDynamicClass( $session, $self->getOption('dataFormId') ) };

    $session->log->fatal( 'Could not instanciate DataForm asset with id ['.$self->getOption('dataFormId').'] in the DataForm exporter plugin.' )
        unless $dataForm;

    return $dataForm;
}

sub processFieldData {
    my $self    = shift;
    my $entryId = shift || return;
    my $session = $self->session;

    my $dataForm    = $self->getDataForm;
    my $entry       = $dataForm->entryClass->new( $session, $entryId );

    my $fieldConfig = $dataForm->getFieldConfig;
    my $entryData   = $entry->fields;

    my @result = map { $dataForm->_createForm( $fieldConfig->{$_}, $entryData->{$_} )->getValueAsHtml } @{ $self->getFields };

    return @result;
}

1;

