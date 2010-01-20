package WebGUI::Asset::Wobject::ScoredSurvey;

use strict;
our $VERSION = '1.15';
use WebGUI::Asset::Wobject;
use WebGUI::Session;
use WebGUI::Form;
use WebGUI::HTMLForm;
use WebGUI::Session::Icon;
use WebGUI::DateTime;
use Tie::IxHash;
use Data::Dumper;
use WebGUI::International;
use WebGUI::Utility;

our @ISA = qw(WebGUI::Asset::Wobject);

#-------------------------------------------------------------------
sub _randomize {
	my $array = $_[1];
	return unless(scalar(@{$array}));
	my $i;
	for ($i = @$array; --$i; ) {
		my $j = int rand ($i+1);
		next if $i == $j;
		@$array[$i,$j] = @$array[$j,$i];
	}
}
#-------------------------------------------------------------------
sub _addResponse {
	my $self    = shift;
    my $rd = shift;
	$rd->{assetId} = $self->get("assetId");
	my ($pres) = $self->session->db->quickArray("SELECT count(*) FROM ScoredSurvey_response WHERE assetId=".$self->session->db->quote($self->get("assetId"))." AND ScoredSurvey_questionId=".$self->session->db->quote($rd->{ScoredSurvey_questionId})." AND ScoredSurvey_respondentId=".$self->session->db->quote($rd->{ScoredSurvey_respondentId}));
	if($pres){
		$self->session->db->write("DELETE FROM ScoredSurvey_response WHERE assetId=".$self->session->db->quote($self->get("assetId"))." AND ScoredSurvey_questionId=".$self->session->db->quote($rd->{ScoredSurvey_questionId})." AND ScoredSurvey_respondentId=".$self->session->db->quote($rd->{ScoredSurvey_respondentId}));
	}
		my (@keys, @values);
		foreach(keys %{$rd}){
			push(@keys, $_);
			push(@values, $rd->{$_});
		}
	$self->session->db->write("INSERT INTO ScoredSurvey_response(".(join(',',@keys)).") VALUES (".(join(',', (map{$self->session->db->quote($_)} @values))).")");

}
#-------------------------------------------------------------------
sub _calculateScore {
	my $self            = shift;
    my $respondentId    = shift;
	my ($score) = $self->session->db->quickArray("SELECT SUM(ScoredSurvey_answer.score) FROM ScoredSurvey_response
    LEFT JOIN ScoredSurvey_answer USING(ScoredSurvey_answerId,ScoredSurvey_questionId ) WHERE
    ScoredSurvey_response.assetId=".$self->session->db->quote($self->get("assetId"))." AND
    ScoredSurvey_response.ScoredSurvey_respondentId=".$self->session->db->quote($respondentId));
	return $score;
}
#-------------------------------------------------------------------
sub _calculateTotalScore {
	my $self            = shift;
	my ($score) = $self->session->db->quickArray("SELECT SUM(ScoredSurvey_answer.score) FROM ScoredSurvey_response
    LEFT JOIN ScoredSurvey_answer USING(ScoredSurvey_answerId,ScoredSurvey_questionId ) WHERE
    ScoredSurvey_response.assetId=".$self->session->db->quote($self->get("assetId")));
	return $score;
}
#-------------------------------------------------------------------
sub _canVote {
    my $self    = shift;
    my $session = $self->session;
    if ($session->stow->get("wg_ScoredSurvey_".$self->get("assetId")."_status") eq $self->get("surveyNumber")){
        return 0;
    } else {
        return $session->http->getCookies->{"wg_ScoredSurvey_".$self->get("assetId")."_status"} ne
                        $self->get("surveyNumber");
    }
}
#-------------------------------------------------------------------
sub _resetSurvey {
    my $self    = shift;
    my $session = $self->session;
	if ($self->get('canTakeAgain')) {
        $session->http->setCookie("wg_ScoredSurvey_".$self->get("assetId")."_status", '');
		$session->http->setCookie('wg_ScoredSurvey_'.$self->get("assetId").'_rid', '');
        $session->http->setCookie("wg_ScoredSurvey_".$self->get("assetId")."_pn",0);
        $session->stow->set("wg_ScoredSurvey_".$self->get("assetId")."_status", '');
		$session->stow->set('wg_ScoredSurvey_'.$self->get("assetId").'_rid', '');
        $session->stow->set("wg_ScoredSurvey_".$self->get("assetId")."_pn",0);
    }
}
#-------------------------------------------------------------------
sub _closeSurvey {
    my $self    = shift;
    my $session = $self->session;
	$session->http->setCookie("wg_ScoredSurvey_".$self->get("assetId")."_status", $self->get("surveyNumber"));
    $session->stow->set("wg_ScoredSurvey_".$self->get("assetId")."_status", $self->get("surveyNumber"));
	#$session->http->getCookies->{"wg_ScoredSurvey_".$self->get("assetId")."_status"} = $self->get("surveyNumber");
}
#-------------------------------------------------------------------
sub _createPageBounds {
    my $self    = shift;
    my $session = $self->session;
	my ($pagebreaks, $maxnr, %page);
	$pagebreaks = $self->session->db->buildArrayRef("SELECT sequenceNumber FROM ScoredSurvey_question WHERE type='pagebreak' AND assetId=".$self->session->db->quote($self->get("assetId"))." ORDER BY sequenceNumber");
	($maxnr) = $self->session->db->quickArray("SELECT MAX(sequenceNumber) FROM ScoredSurvey_question WHERE assetId=".$self->session->db->quote($self->get("assetId")));
	if(scalar(@{$pagebreaks})){
		for(my $i=0; $i<scalar(@{$pagebreaks}); $i++){
			$page{($i+1)}{low} = ($i==0)? 0 : $pagebreaks->[($i-1)];
			$page{($i+1)}{up} = $pagebreaks->[$i];
		}
		$page{(scalar(@{$pagebreaks})+1)}{low} = $pagebreaks->[(scalar(@{$pagebreaks})-1)];
		$page{(scalar(@{$pagebreaks})+1)}{up} = $maxnr+1;
		$page{total} = (scalar(@{$pagebreaks})+1);
	}else{
		$page{1}{low} = 0;
		$page{1}{up} = $maxnr+1;
		$page{total} = 1;
	}

	return \%page;
}
#-------------------------------------------------------------------
sub _editSubmenu {
    my $self    = shift;
    my $content = shift;
    my $session = $self->session;
    my %url;
    my $output;
	return $output if ($session->form->param('makePrintable'));
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	%url = (
		'newScoreQuestion'=>$self->getUrl('func=editQuestion&qid=new&type=score&wid='.$self->get("assetId")),
		'newOpenQuestion'=>$self->getUrl('func=editQuestion&qid=new&type=open&wid='.$self->get("assetId")),
		'newPageBreak'=>$self->getUrl('func=editQuestion&qid=new&type=pagebreak&wid='.$self->get("assetId")),
		'newCategory'=>$self->getUrl('func=editCategory&cid=new&wid='.$self->get("assetId")),
        'resetVotesURL'=>$self->getUrl('func=resetVotes&wid='.$self->get("assetId"))
		);

        $output .= '<table width="100%" border="0" cellpadding="5" cellspacing="0">
                <tr><td width="70%" class="tableData" valign="top">';
        $output .= $content;
        $output .= '</td><td width="30%" class="tableMenu" valign="top">';
	$output .= '<li><a href="'.$self->getUrl('func=viewQA&wid='.$self->get("assetId")).'">'.$i18n->get(51).'</a>';
	$output .= '<li><a href="'.$self->getUrl('func=viewCategories&wid='.$self->get("assetId")).'">'.$i18n->get(52).'</a>';
	if($session->stow->get('mode') eq 'manageQA'){
		$output .= '<li><a href="'.$url{'newScoreQuestion'}.'">'.$i18n->get(24).'</a>';
		$output .= '<li><a href="'.$url{'newOpenQuestion'}.'">'.$i18n->get(25).'</a>';
	$output .= '<li><a href="'.$url{'newPageBreak'}.'">'.$i18n->get(26).'</a>';
	}
	if($session->stow->get('mode') eq 'manageCategories'){
		$output .= '<li><a href="'.$url{'newCategory'}.'">'.$i18n->get(30).'</a>';
	}
	$output .= '<li><a href="'.$self->getUrl().'">'.$i18n->get(27).'</a>';
	$output .= '<li><a href="'.$url{'resetVotesURL'}.'">Reset votes</a>';
    $output .= '</td></tr></table>';
    return $self->processStyle($output);
}

#-------------------------------------------------------------------
sub _getAnswers {
	my $self    = shift;
    my $qid     = shift;
	my (@answers, $sth);
	$sth = $self->session->db->read("   SELECT *
                                        FROM ScoredSurvey_answer
                                        WHERE ScoredSurvey_questionId=?
                                        ORDER BY sequenceNumber
                                        ",[$qid]);
	while (my $a = $sth->hashRef){
		push(@answers, $a);
	}
	$sth->finish();
	return \@answers;
}
#-------------------------------------------------------------------
sub _getAnswerCount {
	my $self    = shift;
	my ($answers, $sth);
	$answers = $self->session->db->buildHashRef("SELECT ScoredSurvey_answer.ScoredSurvey_answerId , COUNT(ScoredSurvey_response.ScoredSurvey_answerId) FROM ScoredSurvey_answer LEFT JOIN ScoredSurvey_response USING(ScoredSurvey_answerId) WHERE ScoredSurvey_answer.assetId=".$self->session->db->quote($self->get("assetId"))." GROUP BY ScoredSurvey_answer.ScoredSurvey_answerId");
	return $answers;
}
#-------------------------------------------------------------------
sub _getQuestions {
	my $self    = shift;
	my (@questions, $sth);
	$sth = $self->session->db->read("SELECT * FROM ScoredSurvey_question WHERE assetId=".$self->session->db->quote($self->get("assetId"))." ORDER BY sequenceNumber");
	while (my $q = $sth->hashRef){
		push(@questions, $q);
	}
	$sth->finish();
	return \@questions;
}
#-------------------------------------------------------------------
sub _getRespondentId {
    my $self    = shift;
    my $session = $self->session;
    my $respondentId = $session->stow->get('wg_ScoredSurvey_'.$self->get("assetId").'_rid')
        || $session->http->getCookies->{'wg_ScoredSurvey_'.$self->get("assetId").'_rid'};
	unless( $respondentId ){
        my $rid = $session->id->generate;
		$self->session->http->setCookie('wg_ScoredSurvey_'.$self->get("assetId").'_rid', $rid);
		$self->session->stow->set('wg_ScoredSurvey_'.$self->get("assetId").'_rid', $rid);
        return $rid;
		#$session->http->getCookies->{'wg_ScoredSurvey_'.$self->get("assetId").'_rid'} = $rid;
	}
	return $respondentId;
}
#-------------------------------------------------------------------
sub _proceed {
    my $self    = shift;
    my $session = $self->session;
	if($session->form->param('proceed') eq 'addAnswer'){
		$session->stow->set('aid', 'new');
		return $self->www_editAnswer();
	}elsif($session->form->param('proceed') eq 'addScoreQuestion'){
		$session->stow->set('qid', 'new');
		$session->stow->set('type', 'score');
		return $self->www_editQuestion();
	}elsif($session->form->param('proceed') eq 'addOpenQuestion'){
		$session->stow->set('qid', 'new');
		$session->stow->set('type', 'open');
		return $self->www_editQuestion();
	}elsif($session->form->param('proceed') eq 'addPageBreak'){
		$session->stow->set('qid', 'new');
		$session->stow->set('type', 'pagebreak');
		return $self->www_editQuestion();
	}
	return $self->www_viewQA();
}
#-------------------------------------------------------------------
sub _reportSubmenu {
    my $self    = shift;
    my $session = $self->session;
    my $output  = shift;
	return $_[1] if ($session->form->param('makePrintable'));
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
        $output .= '<table width="100%" border="0" cellpadding="5" cellspacing="0">
                <tr><td width="70%" class="tableData" valign="top">';
        $output .= $_[1];
        $output .= '</td><td width="30%" class="tableMenu" valign="top">';
	$output .= '<li><a href="'.$self->getUrl('func=scoreStatistics&wid='.$self->get("assetId")).'">'.$i18n->get(60).'</a>';
	$output .= '<li><a href="'.$self->getUrl('func=statisticalOverview&wid='.$self->get("assetId")).'">'.$i18n->get(70).'</a>';
	$output .= '<li><a href="'.$self->getUrl('func=exportQuestions&wid='.$self->get("assetId")).'">'.$i18n->get(80).'</a>';
	$output .= '<li><a href="'.$self->getUrl('func=exportAnswers&wid='.$self->get("assetId")).'">'.$i18n->get(81).'</a>';
	$output .= '<li><a href="'.$self->getUrl('func=exportResponses&wid='.$self->get("assetId")).'">'.$i18n->get(82).'</a>';
	$output .= '<li><a href="'.$self->getUrl().'">'.$i18n->get(27).'</a>';
    $output .= '</td></tr></table>';
    return $self->processStyle($output);
}
#-------------------------------------------------------------------
sub duplicate {
	my $self    = shift;
	my ($w, $questions, $sth);
	$w = $self->SUPER::duplicate($_[1]);
        $w = WebGUI::Wobject::ScoredSurvey->new({assetId=>$w,namespace=>$self->get("namespace")});
	$questions = $self->_getQuestions();
	foreach my $q (@{$questions}){
		my $answers = $self->_getAnswers($q->{ScoredSurvey_questionId});
		$q->{ScoredSurvey_questionId} = 'new';
		$q->{assetId} = $w->get("assetId");
		my $qid = $w->setCollateral("ScoredSurvey_question", "ScoredSurvey_questionId", $q, 1,1);
		foreach my $a (@{$answers}){
			$a->{ScoredSurvey_answerId} = 'new';
			$a->{assetId} = $w->get("assetId");
			$a->{ScoredSurvey_questionId} = $qid;
			$w->setCollateral("ScoredSurvey_answer", "ScoredSurvey_answerId", $a, 1, 1, "ScoredSurvey_questionId", $qid);
		}
	}
	$sth = $self->session->db->read("SELECT * FROM ScoredSurvey_category WHERE assetId=".$self->session->db->quote($self->get("assetId")));
	while (my $cat = $sth->hashRef){
		$cat->{ScoredSurvey_categoryId} = 'new';
		$cat->{assetId} = $w->get("assetId");
		$w->setCollateral("ScoredSurvey_category", "ScoredSurvey_categoryId", $cat, 1, 1);
	}

}

#-------------------------------------------------------------------
sub definition {
    my $class = shift;
    my $session = shift;
    my $definition = shift;
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	my %access;
    tie %access, "Tie::IxHash";
	%access = (
		'cookie'=>'Cookie based',
		'ip-user'=>'ip-address / user based',
		'none'=>'None'
		);
    push(@{$definition}, {
        assetName=>$i18n->get('assetName'),
        icon=>'sqlReport.gif',
        tableName=>'ScoredSurvey',
        className=>'WebGUI::Asset::Wobject::ScoredSurvey',
        properties=>{
            templateId => {
                fieldType   => 'template',
                defaultValue    => 'PBtmpl0000000000000061',
                tab=>"display",
                hoverHelp=>"view template",
                label=>"view template",
                namespace  => 'ScoredSurvey',
                afterEdit  => 'func=edit'
            },
            groupToViewReports=>{
                fieldType=>"group",
                defaultValue=>4,
                tab=>"security",
                hoverHelp=>"group te view reports",
                label=>"group to view reports"
            },
            responseText=>{
                fieldType=>'text',
                tab=>"properties",
                hoverHelp=>"response text",
                label=>"respose text"
            },
            responseTemplateId=>{
                fieldType=>"template",
                defaultValue=>"template",
                namespace=>"ScoredSurvey/Response",
                tab=>"display",
                hoverHelp=>"response template",
                label=>"response template"
            },
            accessControl=>{
                fieldType=>'RadioList',
                defaultValue => 'none',
                tab=>"security",
                hoverHelp=>"Access restriction",
                label=>"Access restriction",
			    options=>\%access
            },
            groupToTakeSurvey => {
                fieldType   => 'group',
                defaultValue    => 2,
                tab=>"security",
                hoverHelp=>"Group to take survey",
                label=>"Group to take survey",

            },
            surveyNumber => {
                fieldType   => 'hidden',
                defaultValue=>1
            },
            canTakeAgain => {
                fieldType       => 'yesNo',
                defaultValue    =>  0,
                label           =>  'Can take again',
                hoverHelp       =>  'If checked, the user will get an option to take the survey again'
            },
            answerEditor => {
                fieldType       => 'selectBox',
                defaultValue    => 'HTMLArea',
                label           => 'Answer editor',
                hoverhelp       => 'Choose the editor for editing answers.',
                options         =>{ HTMLArea=>'HTMLArea',Textarea=>'Textarea'}
            }
        },
        autoGenerateForms=>1
    });
    return $class->SUPER::definition($session, $definition);
}

#-------------------------------------------------------------------
sub purge {
	my $self    = shift;
	$self->session->db->write("DELETE FROM ScoredSurvey_question WHERE assetId=".$self->session->db->quote($self->get("assetId")));
	$self->session->db->write("DELETE FROM ScoredSurvey_answer WHERE assetId=".$self->session->db->quote($self->get("assetId")));
	$self->session->db->write("DELETE FROM ScoredSurvey_response WHERE assetId=".$self->session->db->quote($self->get("assetId")));
	$self->SUPER::purge();
}

#-------------------------------------------------------------------
sub getUiLevel {
	return 5;
}

#-------------------------------------------------------------------
sub www_resetSurvey {
    my $self    = shift;
    $self->_resetSurvey;
    $self->session->http->setRedirect($self->getUrl);
}

#-------------------------------------------------------------------
sub www_deleteAnswer {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	return $self->confirm("Are you sure you want to delete this answer?",
			$self->getUrl('func=deleteAnswerConfirm&wid='.$self->get("assetId").'&qid='.$session->form->param('qid').'&aid='.$session->form->param('aid')),
			$self->getUrl('func=viewQA&wid='.$self->get("assetId")));
}
#-------------------------------------------------------------------
sub www_deleteAnswerConfirm {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->deleteCollateral("ScoredSurvey_answer","ScoredSurvey_answerId", $session->form->param('aid'));
	$self->reorderCollateral("ScoredSurvey_answer","ScoredSurvey_answerId","ScoredSurvey_questionId",
            $session->form->param('qid'));
	return $self->www_viewQA();
}
#-------------------------------------------------------------------
sub www_deleteCategory {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	return $self->confirm("Are you sure you want to delete this score category?",
			$self->getUrl('func=deleteCategoryConfirm&wid='.$self->get("assetId").'&cid='.$session->form->param('cid')),
			$self->getUrl('func=viewCategories&wid='.$self->get("assetId")));
}
#-------------------------------------------------------------------
sub www_deleteCategoryConfirm {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->deleteCollateral("ScoredSurvey_category","ScoredSurvey_categoryId", $session->form->param('cid'));
	$self->reorderCollateral("ScoredSurvey_category", "ScoredSurvey_categoryId");
	return $self->www_viewCategories();
}
#-------------------------------------------------------------------
sub www_deleteQuestion {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	return $self->confirm("Are you sure you want to delete this question?",
			$self->getUrl('func=deleteQuestionConfirm&wid='.$self->get("assetId").'&qid='.$session->form->param('qid')),
			$self->getUrl('func=viewQA&wid='.$self->get("assetId")));
}
#-------------------------------------------------------------------
sub www_deleteQuestionConfirm {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->deleteCollateral("ScoredSurvey_answer","ScoredSurvey_questionId", $session->form->param('qid'));
	$self->deleteCollateral("ScoredSurvey_question","ScoredSurvey_questionId", $session->form->param('qid'));
	$self->reorderCollateral("ScoredSurvey_question", "ScoredSurvey_questionId");
	return $self->www_viewQA();
}

#-------------------------------------------------------------------
sub www_editAnswer {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	my ($output, $f, $answer, %next);
	$answer = $self->getCollateral("ScoredSurvey_answer",
                    "ScoredSurvey_answerId",
                    $session->stow->get('aid') || $session->form->param('aid')
                );

	$output = '<h1>'.$i18n->get(20).'</h1>';
    $session->stow->set('qid',$session->form->param('qid')) unless ($session->form->param('qid') eq 'new');
	$f = WebGUI::HTMLForm->new($session);
	$f->hidden(name=>"wid", value=>$self->get("assetId"));
	$f->hidden(name=>"func", value=>"editAnswerSave");
	$f->hidden(     name=>"qid",
                    value=>$session->stow->get('qid') || $session->form->param('qid')
                );
	$f->hidden(name=>"aid", value=>$answer->{ScoredSurvey_answerId});
	if ($self->get('answerEditor') eq 'Textarea') {
        $f->Textarea(
		    -name=>"answer",
		    -label=>$i18n->get(21),
		    -value=>$answer->{answer}
		    );
    } else {
        $f->HTMLArea(
		    -name=>"answer",
		    -label=>$i18n->get(21),
		    -value=>$answer->{answer}
		    );
    }
	$f->integer(
		-name=>"score",
		-label=>$i18n->get(22),
		-value=>$answer->{score}
		);
	if( ($session->stow->get('aid') eq 'new') || ($session->form->param('aid') eq 'new') ){
		%next = (
			"addAnswer"=>$i18n->get(23),
			"addScoreQuestion"=>$i18n->get(24),
			"addOpenQuestion"=>$i18n->get(25),
			"addPageBreak"=>$i18n->get(26),
			"backToPage"=>$i18n->get(27)
			);
		$f->whatNext(
			-options=>\%next,
			-value=>"addAnswer"
			);
	}
	$f->submit();
	$output .= $f->print();
	return $self->processStyle($output);
}
#-------------------------------------------------------------------
sub www_editAnswerSave {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->setCollateral("ScoredSurvey_answer", "ScoredSurvey_answerId", {
			ScoredSurvey_answerId=>$session->form->param('aid'),
			ScoredSurvey_questionId=>$session->form->param('qid'),
			answer=>$session->form->param('answer'),
			score=>$session->form->param('score')
			},1,1, "ScoredSurvey_questionId", $session->form->param('qid'));
	return $self->_proceed();
}
#-------------------------------------------------------------------
sub www_editCategory {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	my ($output, $f, $cat);
	$cat = $self->getCollateral("ScoredSurvey_category", "ScoredSurvey_categoryId", $session->form->param('cid'));

	$output = '<h1>'.$i18n->get(30).'</h1>';
	$f = WebGUI::HTMLForm->new($session);
	$f->hidden(name=>"wid", value=>$self->get("assetId"));
	$f->hidden(name=>"func", value=>"editCategorySave");
	$f->hidden(name=>"cid", value=>$cat->{ScoredSurvey_categoryId});
	$f->text(
		-name=>'title',
		-label=>$i18n->get(31),
		-value=>$cat->{title}
		);
	$f->HTMLArea(
		-name=>'description',
		-label=>$i18n->get(32),
		-value=>$cat->{description}
		);
	$f->integer(
		-name=>'fromScore',
		-label=>$i18n->get(33),
		-value=>$cat->{fromScore}
		);
	$f->integer(
		-name=>'toScore',
		-label=>$i18n->get(34),
		-value=>$cat->{toScore}
		);
	$f->submit();

	$output .= $f->print();
	return $self->processStyle($output);
}
#-------------------------------------------------------------------
sub www_editCategorySave {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->setCollateral("ScoredSurvey_category", "ScoredSurvey_categoryId", {
			ScoredSurvey_categoryId=>$session->form->param('cid'),
			title=>$session->form->param('title'),
			description=>$session->form->param('description'),
			fromScore=>$session->form->param('fromScore'),
			toScore=>$session->form->param('toScore')
			}, 1, 1);
	return $self->www_viewCategories();
}
#-------------------------------------------------------------------
sub www_editQuestion {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	my ($output, $f, $question);
	$question = $self->getCollateral(
                    "ScoredSurvey_question",
                    "ScoredSurvey_questionId",
                    $session->stow->get('qid') || $session->form->param('qid')
                );
	if( ($session->stow->get('qid') eq 'new') || ($session->form->param('qid') eq 'new') ){
		$question->{type} = $session->stow->get('type') || $session->form->param('type');
	}

	$output = '<h1>'.$i18n->get(40).'</h1>';
	$f = WebGUI::HTMLForm->new($session);
	$f->hidden(name=>"wid", value=>$self->get("assetId"));
	$f->hidden(name=>"func", value=>"editQuestionSave");
	$f->hidden(name=>"qid", value=>$question->{ScoredSurvey_questionId});
	$f->hidden(name=>"type", value=>$question->{type});
	if($question->{type} eq 'pagebreak'){
		$output = '<h1>'.$i18n->get(42).'</h1>';
		$f->HTMLArea(
			-name=>"question",
			-label=>$i18n->get(32),
			-value=>$question->{question}
			);
	}else{
		$output = '<h1>'.$i18n->get(40).'</h1>';
		$f->HTMLArea(
			-name=>"question",
			-label=>$i18n->get(41),
			-value=>$question->{question}
			);
	}
	if($question->{type} eq 'score'){
		$f->yesNo(
			-name=>"randomAnswers",
			-label=>$i18n->get(43),
			-value=>$question->{randomAnswers}
			);
	}
	if( ($session->stow->get('qid') eq 'new') || ($session->form->param('qid') eq 'new') ){
		my %next;
		$next{'addAnswer'} = $i18n->get(23) if($question->{type} eq 'score');
		%next = ( %next, (
			"addScoreQuestion"=>$i18n->get(24),
			"addOpenQuestion"=>$i18n->get(25),
			"addPageBreak"=>$i18n->get(26),
			"backToPage"=>$i18n->get(27)
			));
		$f->whatNext(
			-options=>\%next,
			-value=>"backToPage"
			);
	}

	$f->submit();
	$output .= $f->print();
	return $self->processStyle($output);
}
#-------------------------------------------------------------------
sub www_editQuestionSave {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$session->stow->set('randomAnswers', 0) unless($session->form->param('randomAnswers'));
	my $qid = $self->setCollateral("ScoredSurvey_question", "ScoredSurvey_questionId", {
			ScoredSurvey_questionId=>$session->form->param('qid'),
			question=>$session->form->param('question'),
			type=>$session->form->param('type'),
			randomAnswers=>$session->form->param('randomAnswers') ||  $session->stow->get('randomAnswers')
			},1,1);
    $session->stow->set('qid', $qid);
	return $self->_proceed();
}
#-------------------------------------------------------------------
sub www_exportAnswers {
    my $self    = shift;
    my $session = $self->session;
	return "" unless ($session->user->isInGroup($self->get("groupToViewReports")));
    $self->session->http->setFilename($self->session->url->escape($self->get("title")."_answers.tab"),"text/tab");
	return $self->session->db->quickTab("SELECT ScoredSurvey_questionId as questionId, ScoredSurvey_answerId as answerId, answer, score, sequenceNumber FROM ScoredSurvey_answer WHERE assetId=".$self->session->db->quote($self->get("assetId"))." ORDER BY ScoredSurvey_questionId, sequenceNumber");
}
#-------------------------------------------------------------------
sub www_exportQuestions {
    my $self    = shift;
    my $session = $self->session;
	return "" unless ($session->user->isInGroup($self->get("groupToViewReports")));
    $self->session->http->setFilename($self->session->url->escape($self->get("title")."_questions.tab"),"text/tab");
	return $self->session->db->quickTab("SELECT ScoredSurvey_questionId as questionId, question, type, sequenceNumber FROM ScoredSurvey_question WHERE type!='pagebreak' AND assetId=".$self->session->db->quote($self->get("assetId"))." ORDER BY sequenceNumber");
}
#-------------------------------------------------------------------
sub www_exportResponses {
    my $self    = shift;
    my $session = $self->session;
	return "" unless ($session->user->isInGroup($self->get("groupToViewReports")));
    $self->session->http->setFilename($self->session->url->escape($self->get("title")."_responses.tab"),"text/tab");
	return $self->session->db->quickTab("SELECT ScoredSurvey_respondentId as respondentId, ScoredSurvey_questionId as questionId, ScoredSurvey_answerId as answerId, answer, responseDate, userId, ipAddress FROM ScoredSurvey_response WHERE assetId=".$self->session->db->quote($self->get("assetId"))." ORDER BY ScoredSurvey_respondentId");
}
#-------------------------------------------------------------------
sub www_moveAnswerDown {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->moveCollateralDown("ScoredSurvey_answer", "ScoredSurvey_answerId", $session->form->param('aid'),
            "ScoredSurvey_questionId", $session->form->param('qid'));
	return $self->www_viewQA();
}
#-------------------------------------------------------------------
sub www_moveAnswerUp {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->moveCollateralUp("ScoredSurvey_answer", "ScoredSurvey_answerId", $session->form->param('aid'),
            "ScoredSurvey_questionId", $session->form->param('qid'));
	return $self->www_viewQA();
}
#-------------------------------------------------------------------
sub www_moveCategoryDown {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->moveCollateralDown("ScoredSurvey_category", "ScoredSurvey_categoryId", $session->form->param('cid'));
	return $self->www_viewCategories();
}
#-------------------------------------------------------------------
sub www_moveCategoryUp {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->moveCollateralUp("ScoredSurvey_category", "ScoredSurvey_categoryId", $session->form->param('cid'));
	return $self->www_viewCategories();
}
#-------------------------------------------------------------------
sub www_moveQuestionDown {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->moveCollateralDown("ScoredSurvey_question", "ScoredSurvey_questionId", $session->form->param('qid'));
	return $self->www_viewQA();
}
#-------------------------------------------------------------------
sub www_moveQuestionUp {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->moveCollateralUp("ScoredSurvey_question", "ScoredSurvey_questionId", $session->form->param('qid'));
	return $self->www_viewQA();
}
#-------------------------------------------------------------------
sub www_resetVotes {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	return $self->processStyle( $self->confirm("Are you sure you want to delete all responses?",
			$self->getUrl('func=resetVotesConfirm&wid='.$self->get("assetId")),
			$self->getUrl('func=editwid='.$self->get("assetId"))) );
}
#-------------------------------------------------------------------
sub www_resetVotesConfirm {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
	$self->session->db->write("DELETE FROM ScoredSurvey_response WHERE assetId=".$self->session->db->quote($self->get("assetId")));
	$self->update({surveyNumber=>$self->get("surveyNumber")+1});
	return $self->www_viewQA;
}
#-------------------------------------------------------------------
sub www_respond {
    my $self    = shift;
    my $session = $self->session;
	my ($pn, $page);
    $self->session->http->setCacheControl("none");
    $pn = $self->session->form->param('page') || 1;
    $session->http->setCookie("wg_ScoredSurvey_".$self->get("assetId")."_pn",$pn);
	$page = $self->_createPageBounds();
	if($self->_canVote()){
		my ($rid, $fd, $qs, $cd);
		$qs = $self->session->db->buildHashRef("SELECT ScoredSurvey_questionId, type FROM ScoredSurvey_question WHERE assetId=".$self->session->db->quote($self->get("assetId")));
		my $rid = $self->_getRespondentId();
        foreach my $key ($self->session->form->param) {
            if ($key =~ /^ScoredSurvey_question_(.+)$/) {
				if($qs->{$1} eq 'score'){
					$cd->{ScoredSurvey_answerId} = $session->form->param($key);
					$cd->{answer} = ''
				}elsif($qs->{$1} eq 'open'){
					$cd->{answer} = $session->form->param($key);
					$cd->{ScoredSurvey_answerId} = '';
				}
				$cd->{ScoredSurvey_questionId} = $1;
				$cd->{ScoredSurvey_respondentId} = $rid;
				$cd->{responseDate} = $session->datetime->time();
				$cd->{userId} = $session->user->userId;
				$cd->{ipAddress} = $session->env('REMOTE_ADDR');
				$self->_addResponse($cd);
			}
		}
        if($pn > $page->{total}) {
            $self->_closeSurvey();
        }
		return $self->www_view;
	}
	return '';
}

#-------------------------------------------------------------------

=head2 prepareView ( )

See WebGUI::Asset::prepareView() for details.

=cut

sub prepareView {
    my $self = shift;
    my $session = $self->session;
    $self->SUPER::prepareView();
    $session->stow->set("pn",$session->http->getCookies->{"wg_ScoredSurvey_".$self->get("assetId")."_pn"} || 1);
    my $template = WebGUI::Asset::Template->new($self->session, $self->get("templateId"));
    $template->prepare($self->getMetaDataAsTemplateVariables);
    $self->{_viewTemplate} = $template;
}

#-------------------------------------------------------------------
sub www_view {
    my $self = shift;
    $self->session->http->setCacheControl('none');
    $self->SUPER::www_view(@_);
}

#-------------------------------------------------------------------
sub view {
    my $self    = shift;
    my $session = $self->session;
	my (%var, $pn, $page);
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	$pn = $session->form->param('page') || $session->stow->get('pn') || 1;
	$page = $self->_createPageBounds();
	$var{'survey_started'} = 1;
	$var{'survey_finished'} = 0;
    ($var{'survey_score'}) = $self->_calculateScore($self->_getRespondentId());
    ($var{'total_score'}) = $self->_calculateTotalScore();
	my ($sth, @question_loop);
	$sth = $self->session->db->read("SELECT * FROM ScoredSurvey_question WHERE assetId=".$self->session->db->quote($self->get("assetId"))." AND sequenceNumber >= ".$self->session->db->quote($page->{$pn}{low})." AND sequenceNumber < ".$self->session->db->quote($page->{$pn}{up})." ORDER BY sequenceNumber");
	 my $lastSequenceNumber  ;
     my $firstQuestion = 1;
     while (my $q = $sth->hashRef){
		if($q->{type} eq 'pagebreak'){
			$var{'page_description'} = $q->{question};
		}else{
			$q->{'type_is_'.$q->{type}} = 1;

			if($q->{type} eq 'score'){
				my $answers = $self->_getAnswers($q->{ScoredSurvey_questionId});
				$self->_randomize($answers) if($q->{randomAnswers});
				$q->{'answer_loop'} = $answers;
                my $answer = $session->db->buildHashRef("select ScoredSurvey_answerId,answer from ScoredSurvey_answer
                     where ScoredSurvey_questionId=? order by sequenceNumber",[$q->{ScoredSurvey_questionId}]);
                if ($q->{randomAnswers}) {
                    $answer = randomizeHash($answer);
                }
                $q->{'form_answer'} = WebGUI::Form::radioList($session, {
                        options=>$answer,
                        name=>"ScoredSurvey_question_".$q->{ScoredSurvey_questionId},
                        vertical=>1
                });

    		} else {
                $q->{'form_answer'} .= WebGUI::Form::text($self->session,{
                                name=>'ScoredSurvey_question_'.$q->{ScoredSurvey_questionId}
                        });
            }

            push(@question_loop, $q);
		}
        if ($firstQuestion) {
            $lastSequenceNumber  = $self->session->db->quickScalar(' SELECT MAX(sequenceNumber)
                                                    FROM ScoredSurvey_question
                                                    WHERE assetId=?
                                                    AND sequenceNumber<?
                                                    AND type <> "pagebreak"'
                                                    ,[$self->get("assetId"),$q->{sequenceNumber}]);
		    $firstQuestion = 0;
        }
	}

    #get last sequencenumber
    if ($lastSequenceNumber) {
        #$lastSequenceNumber  = $self->session->db->quickScalar(' SELECT MAX(sequenceNumber)
        #                                                FROM ScoredSurvey_question
        #                                                WHERE assetId=?
        #                                                AND type <> "pagebreak"'
        #                                                ,[$self->get("assetId")]);

    my ($previousQuestion,$previousQuestionId) = $self->session->db->quickArray('SELECT question ,
                                                        ScoredSurvey_questionId
                                                        FROM ScoredSurvey_question
                                                        WHERE assetId=?
                                                        AND sequenceNumber=?
                                                        AND type <> "pagebreak"'
                                                        ,[$self->get("assetId"),$lastSequenceNumber]);
    $var{'previous_question'} = $previousQuestion;
    $var{'previous_question_id'} = $previousQuestionId;
    my ($previousAnswer,$previousAnswerId) = $self->session->db->quickArray('SELECT answer,ScoredSurvey_answerId
                                                        FROM ScoredSurvey_response
                                                        WHERE assetId=?
                                                        AND ScoredSurvey_questionId=?
                                                        AND userId=?
                                                        AND ScoredSurvey_respondentId = ?'
                                                        ,[$self->get("assetId"),$previousQuestionId,$self->session->user->userId,$self->_getRespondentId]);
    if ($previousAnswerId ne '') {
        $previousAnswer = $self->session->db->quickScalar('SELECT answer
                                                        FROM ScoredSurvey_answer
                                                        WHERE ScoredSurvey_answerId=?',
                                                        [$previousAnswerId]);

    }
    $var{'previous_answer'}  = $previousAnswer;


    my $previousAnswers = $self->session->db->buildArrayRefOfHashRefs('
                                                        SELECT answer, score, IF(ScoredSurvey_answerId=?,1,0) as selected
                                                        FROM ScoredSurvey_answer
                                                        WHERE ScoredSurvey_questionId=?
                                                        ',[$previousAnswerId,$previousQuestionId]);
    $var{'previous_answers'}  = $previousAnswers if ($previousAnswers);


    $var{'previous_score'}   = $self->session->db->quickScalar('SELECT score
                                                       FROM ScoredSurvey_answer,ScoredSurvey_response
                                                        WHERE ScoredSurvey_response.assetId=?
                                                        AND ScoredSurvey_response.ScoredSurvey_questionId=?
                                                        AND
                                                        ScoredSurvey_response.ScoredSurvey_answerId=ScoredSurvey_answer.ScoredSurvey_answerId
                                                        AND userId=?
                                                        AND ScoredSurvey_respondentId = ?'
                                                        ,[$self->get("assetId"),$previousQuestionId,$self->session->user->userId,$self->_getRespondentId]);
    }
    $sth->finish();
	$var{'question_loop'} = \@question_loop;

	my $numberOfQuestions = $self->session->db->quickScalar("
                                                        SELECT count(*)
                                                        FROM ScoredSurvey_question
                                                        WHERE assetId=".$self->session->db->quote($self->get("assetId"))."
                                                        AND type <> 'pagebreak'
                                                        ");
	$var{'form_end'} =  WebGUI::Form::formFooter($self->session);
	$var{'question_total'} = $numberOfQuestions;
	$var{'page_number'} = $pn;
	$var{'page_total'} = $page->{total};
	$var{'page_is_'.$pn} = 1;
	$var{'page_is_last'} = ($page->{total} == $pn);

    if($self->_canVote()){
		$var{'form_start'} .= WebGUI::Form::formHeader($self->session,{action => $self->getUrl});
		$var{'form_start'} .= WebGUI::Form::hidden($self->session,{name=>'wid', value=>$self->get("assetId")});
		$var{'form_start'} .= WebGUI::Form::hidden($self->session,{name=>'func', value=>'respond'});
		$var{'form_start'} .= WebGUI::Form::hidden($self->session,{name=>'page', value=>($pn+1)});
        $var{'form_submit'} = WebGUI::Form::submit($self->session,{
                value=>'volgende'
            });


	}else{
		my ($sth, @category_loop);
		$var{'survey_started'} = 1;
		$var{'survey_finished'} = 1;
	    $var{'response_text'} = $self->get('responseText');
		$sth = $self->session->db->read("SELECT * FROM ScoredSurvey_category WHERE assetId=".$self->session->db->quote($self->get("assetId")));
		while(my $cat = $sth->hashRef){
			$cat->{'is_respondent_score'} = ($var{'survey_score'} >= $cat->{fromScore} && $var{'survey_score'} <= $cat->{toScore});
			push(@category_loop, $cat);
		}
		$sth->finish();
		$var{'category_loop'} = \@category_loop;
		$var{'view_response_url'} = $self->getUrl('func=viewIndividualResponse&wid='.$self->get("assetId"));
		$var{'view_response_label'} = $i18n->get(53);
        my $lastSequenceNumber  = $self->session->db->quickScalar(' SELECT MAX(sequenceNumber)
                                                        FROM ScoredSurvey_question
                                                        WHERE assetId=?
                                                        AND type <> "pagebreak"'
                                                        ,[$self->get("assetId")]);
        my ($previousQuestion,$previousQuestionId) = $self->session->db->quickArray('SELECT question ,
                                                        ScoredSurvey_questionId
                                                        FROM ScoredSurvey_question
                                                        WHERE assetId=?
                                                        AND sequenceNumber=?
                                                        AND type <> "pagebreak"'
                                                        ,[$self->get("assetId"),$lastSequenceNumber]);
        $var{'previous_question'} = $previousQuestion;
        $var{'previous_question_id'} = $previousQuestionId;

        my ($previousAnswer,$previousAnswerId) = $self->session->db->quickArray('SELECT answer,ScoredSurvey_answerId
                                                        FROM ScoredSurvey_response
                                                        WHERE assetId=?
                                                        AND ScoredSurvey_questionId=?
                                                        AND userId=?
                                                        AND ScoredSurvey_respondentId = ?'
                                                        ,[$self->get("assetId"),$previousQuestionId,$self->session->user->userId,$self->_getRespondentId]);
        if ($previousAnswerId ne '') {
                   $previousAnswer = $self->session->db->quickScalar('SELECT answer
                                                                      FROM ScoredSurvey_answer
                                                                      WHERE ScoredSurvey_answerId=?',
                                                                      [$previousAnswerId]);

        }
        $var{'previous_answer'}  = $previousAnswer;
        $var{'previous_score'}   = $self->session->db->quickScalar('SELECT score
                                                       FROM ScoredSurvey_answer,ScoredSurvey_response
                                                        WHERE ScoredSurvey_response.assetId=?
                                                        AND ScoredSurvey_response.ScoredSurvey_questionId=?
                                                        AND
                                                        ScoredSurvey_response.ScoredSurvey_answerId=ScoredSurvey_answer.ScoredSurvey_answerId
                                                        AND userId=?
                                                        AND ScoredSurvey_respondentId = ?'
                                                        ,[$self->get("assetId"),$previousQuestionId,$self->session->user->userId,$self->_getRespondentId]);
    $sth->finish();
	$var{'question_loop'} = \@question_loop;

	$var{'form_end'} =  WebGUI::Form::formFooter($self->session);
	$var{'page_number'} = $pn;
	$var{'page_total'} = $page->{total};
	$var{'page_is_'.$pn} = 1;
	}
	if($session->user->isInGroup($self->get("groupToViewReports"))){
		$var{'user_canViewReports'} = 1;
		$var{'reports_url'} = $self->getUrl('func=statisticalOverview&wid='.$self->get("assetId"));
		$var{'reports_label'} = $i18n->get(50);
	}
	if($self->canEdit){
		$var{'canEdit'} = 1;
		$var{'manage_questions_url'} = $self->getUrl('func=viewQA&wid='.$self->get("assetId"));
		$var{'manage_questions_label'} = $i18n->get(51);
		$var{'manage_categories_url'} = $self->getUrl('func=viewCategories&wid='.$self->get("assetId"));
		$var{'manage_categories_label'} = $i18n->get(52);
	}
    if ($self->get('canTakeAgain') ) {
        $var{'canTakeAgain'}   = 1;
        $var{'canTakeAgainUrl'}   = $self->getUrl('func=resetSurvey');
    }

    return $self->processTemplate(\%var, undef, $self->{_viewTemplate});
}
#-------------------------------------------------------------------
sub www_viewQA {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	my ($output, $questions);
    $session->stow->set("mode","manageQA");
	$output .= '<h1>'.$i18n->get(51).'</h1>';

	$questions = $self->_getQuestions();
	$output .= "<ul>";
	foreach my $question (@{$questions}){
		my ($controls, $qt);
		$controls = $self->session->icon->delete('func=deleteQuestion&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId});
		$controls .= $session->icon->edit('func=editQuestion&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId});
		$controls .= $session->icon->moveUp('func=moveQuestionUp&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId});
		$controls .= $session->icon->moveDown('func=moveQuestionDown&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId});
		if($question->{type} eq 'pagebreak'){
			$qt = $controls." [page break]&nbsp;<hr width=\"50%\">";
		}elsif($question->{type} eq 'score'){
			$qt = "$controls $question->{question} <br>";
			$qt .= "<a href='".$self->getUrl('func=editAnswer&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId}.'&aid=new')."'>Add Answer</a>";
			my $answers = $self->_getAnswers($question->{ScoredSurvey_questionId});
			my $at .= "<ul>";
			foreach my $answer (@{$answers}){
				my $controls .= $self->session->icon->delete('func=deleteAnswer&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId}.'&aid='.$answer->{ScoredSurvey_answerId});
				$controls .= $session->icon->edit('func=editAnswer&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId}.'&aid='.$answer->{ScoredSurvey_answerId});
				$controls .= $session->icon->moveUp('func=moveAnswerUp&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId}.'&aid='.$answer->{ScoredSurvey_answerId});
				$controls .= $session->icon->moveDown('func=moveAnswerDown&wid='.$self->get("assetId").'&qid='.$question->{ScoredSurvey_questionId}.'&aid='.$answer->{ScoredSurvey_answerId});
				$at .= "<li>$controls $answer->{answer} [score: $answer->{score}]</li>";
			}
			$at .= "</ul>";
			$qt .= $at;
		}elsif($question->{type} eq 'open'){
			$qt = "$controls $question->{question}";
		}
		$output .= "<li>$qt</li>";
	}
	$output .= "</ul>";
	return $self->_editSubmenu($output);
}
#-------------------------------------------------------------------
sub www_viewCategories {
    my $self    = shift;
    my $session = $self->session;
	return $self->session->privilege->insufficient() unless ($self->canEdit);
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	my ($output, $sth);
	$session->stow->set('mode','manageCategories');

	$output .= '<h1>'.$i18n->get(52).'</h1>';
	$output .= "<ul>";
	$sth = $self->session->db->read("SELECT * FROM ScoredSurvey_category WHERE assetId=".$self->session->db->quote($self->get("assetId"))." ORDER BY sequenceNumber");
    while (my $cat = $sth->hashRef){
		my $controls .= $self->session->icon->delete('func=deleteCategory&wid='.$self->get("assetId").'&cid='.$cat->{ScoredSurvey_categoryId});
		$controls .= $session->icon->edit('func=editCategory&wid='.$self->get("assetId").'&cid='.$cat->{ScoredSurvey_categoryId});
		$controls .= $session->icon->moveUp('func=moveCategoryUp&wid='.$self->get("assetId").'&cid='.$cat->{ScoredSurvey_categoryId});
		$controls .= $session->icon->moveDown('func=moveCategoryDown&wid='.$self->get("assetId").'&cid='.$cat->{ScoredSurvey_categoryId});
		$output .= "<li>$controls&nbsp;$cat->{title}&nbsp;[$cat->{fromScore} - $cat->{toScore}]</li>";
	}
	$sth->finish();
	$output .= "</ul>";
	return $self->_editSubmenu($output);
}
#-------------------------------------------------------------------
sub www_viewIndividualResponse {
    my $self    = shift;
    my $session = $self->session;
    return "" unless ($self->session->user->isInGroup($self->get("groupToViewReports")));
	my ($questions, $response);
    my $var = $self->get;
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	$questions = $self->_getQuestions();
	$response = $self->session->db->buildHashRef("SELECT ScoredSurvey_questionId, ScoredSurvey_answerId FROM ScoredSurvey_response WHERE assetId=".$self->session->db->quote($self->get("assetId"))." AND ScoredSurvey_respondentId=".$self->session->db->quote($self->_getRespondentId));
	foreach my $q (@{$questions}){
		if($q->{type} eq 'score'){
			my $answers = $self->_getAnswers($q->{ScoredSurvey_questionId});
			foreach (@{$answers}){
				$_->{'is_response'} = ($_->{ScoredSurvey_answerId} eq $response->{$q->{ScoredSurvey_questionId}});
			}
			$q->{'answer_loop'} = $answers;
			push(@{$var->{'question_loop'}}, $q);
		}
	}
	$var->{'back_to_survey_url'} = $self->getUrl('func=view&wid='.$self->get("assetId"));
	$var->{'back_to_survey_label'} = $i18n->get(27);
	$var->{'response_text'} = $self->get('responseText');
    return $self->session->style->process($self->processTemplate($var,
                        $self->getValue("responseTemplateId")),$self->getValue("styleTemplateId"));
}
#-------------------------------------------------------------------
sub www_statisticalOverview {
    my $self    = shift;
    my $session = $self->session;
	return "" unless ($session->user->isInGroup($self->get("groupToViewReports")));
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	my ($output, $sth, $questions, $ac);
	$output .= '<h1>'.$i18n->get(70).'</h1>';
	$questions = $self->_getQuestions();
	$ac = $self->_getAnswerCount();

	foreach my $q (@{$questions}){
		next unless($q->{type} eq 'score');
		$output .= '<p><b>'.$q->{question}.'</b>';
		my $answers = $self->_getAnswers($q->{ScoredSurvey_questionId});
		$output .= '<table width="100%" border="1" cellpadding="1" cellspacing="1">';
		$output .= '<tr>';
		$output .= '<td class="tableHeader">'.$i18n->get(61).'</td>';
		$output .= '<td class="tableHeader">'.$i18n->get(62).'</td>';
		$output .= '<td class="tableHeader">'.$i18n->get(63).'</td>';
		$output .= '</tr>';
		my ($tr) = $self->session->db->quickArray("SELECT count(*) FROM ScoredSurvey_response WHERE ScoredSurvey_questionId=".$self->session->db->quote($q->{ScoredSurvey_questionId}));
		$tr = 1 unless($tr);
		foreach my $a (@{$answers}){
			$output .= '<tr>';
			$output .= '<td class="tableData">'.$a->{answer}.'</td>';
			$output .= '<td class="tableData">'.$ac->{$a->{ScoredSurvey_answerId}}.'</td>';
			$output .= '<td class="tableData">'.(sprintf("%.2f", (($ac->{$a->{ScoredSurvey_answerId}})/$tr)*100)).'</td>';
			$output .= '</tr>';
		}
		$output .= '</table><br><br>';
	}
	return $self->_reportSubmenu($output);
}

#-------------------------------------------------------------------
sub www_scoreStatistics {
    my $self    = shift;
    my $session = $self->session;
	return "" unless ($session->user->isInGroup($self->get("groupToViewReports")));
    my $i18n = WebGUI::International->new($session,"Asset_ScoredSurvey");
	my ($sth, %categories, @responses, $total_responses, $output);
	tie %categories, "Tie::IxHash";
	$sth = $self->session->db->read("SELECT * FROM ScoredSurvey_category WHERE assetId=".$self->session->db->quote($self->get("assetId"))." ORDER BY sequenceNumber");
	while(my $cat = $sth->hashRef){
		$cat->{responses} = 0;
		$categories{$cat->{ScoredSurvey_categoryId}} = $cat;
	}
	$sth->finish();
	@responses = $self->session->db->buildArray("SELECT DISTINCT ScoredSurvey_respondentId FROM ScoredSurvey_response WHERE assetId=".$self->session->db->quote($self->get("assetId")));
	$total_responses = scalar(@responses) || 1;
	foreach my $rid (@responses){
		my $score = $self->_calculateScore($rid);
		foreach my $catId (keys %categories){
			if($score >= $categories{$catId}->{fromScore} && $score <= $categories{$catId}->{toScore}){
				$categories{$catId}->{responses}++;
				last;
			}
		}
	}
	$output .= '<h1>'.$i18n->get(60).'</h1>';
	$output .= '<table width="100%" border="1" cellpadding="1" cellspacing="1">';
	$output .= '<tr>';
	$output .= '<td class="tableHeader">'.$i18n->get(71).'</td>';
	$output .= '<td class="tableHeader">'.$i18n->get(33).'</td>';
	$output .= '<td class="tableHeader">'.$i18n->get(34).'</td>';
	$output .= '<td class="tableHeader">'.$i18n->get(72).'</td>';
	$output .= '<td class="tableHeader">'.$i18n->get(63).'</td>';
	$output .= '</tr>';
	foreach my $catId (keys %categories){
		my $perc = sprintf("%.2f",(($categories{$catId}->{responses}/$total_responses)*100));
		$output .= '<tr>';
		$output .= '<td class="tableData">'.'<b>'.$categories{$catId}->{title}.'</b>'.'<p>'.$categories{$catId}->{description}.'</p>'.'</td>';
		$output .= '<td class="tableData">'.$categories{$catId}->{fromScore}.'</td>';
		$output .= '<td class="tableData">'.$categories{$catId}->{toScore}.'</td>';
		$output .= '<td class="tableData">'.$categories{$catId}->{responses}.'</td>';
		$output .= '<td class="tableData">'.$perc.'%</td>';
		$output .= '</tr>';
	}
	$output .= '</table>';
	return $self->_reportSubmenu($output);

}

#-------------------------------------------------------------------

1;
