package WebGUI::Macro::SQLForm_fileAsset;

#-------------------------------------------------------------------
# WebGUI is Copyright 2001-2003 Plain Black LLC.
#-------------------------------------------------------------------
# Please read the legal notices (docs/legal.txt) and the license
# (docs/license.txt) that came with this distribution before using
# this software.
#-------------------------------------------------------------------
# http://www.plainblack.com                     info@plainblack.com
#---------------------------------------------------------------
# This Macro was created by United Knowledge GoI.
# If you would like to use this Macro, please contact us.
# http://www.unitedknowledge.nl
# developmentinfo@unitedknowledge.nl
#-------------------------------------------------------------------

use strict;

#-------------------------------------------------------------------
sub process{
        my $session = shift;
	my ($output);
	my $mFunc = $session->form->param("mFunc");
        
        if ($mFunc eq "addFile"){
                $output = www_addFile($session);
        }elsif($mFunc eq "addFileSave"){
                $output = www_addFileSave($session);
        }
	return $output;
}

#-------------------------------------------------------------------

=head2 www_addFile ( session )

=cut

sub www_addFile {
        my $session = shift;
        $session->http->setCacheControl("none");
        my $i18n = WebGUI::International->new($session, 'Operation_FormHelpers');
        my $f = WebGUI::HTMLForm->new($session);
        $f->hidden(
                name            => 'mFunc',
                value           => 'addFileSave',
                );
        $f->file(
                label           => $i18n->get('File'),
                name            => 'filename',
                size            => 10,
                );
=cut
        $f->submit(
                value           => $i18n->get('Upload'),
                );
        $f->button(
                value           => $i18n->get('Cancel'),
                extras          => 'onclick="history.go(-1);"',
                );
=cut
        my $html = '<h1>'.$i18n->get('Upload new image').'</h1>'.$f->print;
        return $html;

}

#-------------------------------------------------------------------

=head2 www_addFileSave ( session )

Creates an Image asset under the current asset. The filename should be specified in the form. The Edit and View rights from the current asset are used if not specified in the form. All other properties are copied from the current asset.

=cut

sub www_addFileSave {
        my $session = shift;
        $session->http->setCacheControl("none");
        # get base url
        my $base = WebGUI::Asset->newByUrl($session) || WebGUI::Asset->getRoot($session);
        #my $base = $session->asset;
        my $url = $base->getUrl;
        # check if user can edit the current asset
        return $session->privilege->insufficient('bare') unless $base->canEdit;

        my $storage = WebGUI::Storage->create($session);
        my $filename = $storage->addFileFromFormPost('filename');
	my $newAsset;
        if ($filename) {
                $newAsset =  $base->addChild({
                        assetId     => 'new',
                        className   => 'WebGUI::Asset::File',
                        storageId   => $storage->getId,
                        filename    => $filename,
                        title       => $filename,
                        menuTitle   => $filename,
                        templateId  => 'PBtmpl0000000000000088',
                        url         => $url.'/'.$filename,
                        groupIdEdit => $session->form->process('groupIdEdit') || $base->get('groupIdEdit'),
                        groupIdView => $session->form->process('groupIdView') || $base->get('groupIdView'),
                        ownerUserId => $session->var->get('userId'),
                        isHidden    => 1,
                        });
                #$storage->generateThumbnail($filename);
        }
	#my $scratch = WebGUI::Session::Scratch->new($session);
	#$scratch->set("SQLForm_fileAssetId",$newAsset->get("assetId"));
        #$session->http->setRedirect($url.'?op=richEditImageTree');
        return $newAsset->get("assetId");
}


1;        
