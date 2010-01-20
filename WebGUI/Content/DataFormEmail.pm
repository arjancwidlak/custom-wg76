package WebGUI::Content::DataFormEmail;

#-------------------------------------------------------------------
sub handler {
    my ($session) = @_;
    
    return undef unless $session->form->process( 'dataform' ) eq 'checkEmail';


    $session->http->setMimeType( 'text/plain' );

    my $assetId = $session->form->process('assetId');
    my $email   = $session->form->process('email');

#    return 'error: invalid email address'

    my $hasBeenSent = $session->db->quickScalar( 'select 1 from DataForm_entry where assetId=? and entryData like ?', [
        $assetId,
        '%'.$email.'%',
    ] );

    return $hasBeenSent == 1 ? '0' : '1';
}

1;

