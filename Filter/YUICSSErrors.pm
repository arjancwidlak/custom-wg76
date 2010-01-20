#File:/data/custom/WebGUI/Filter::YUICSSErrors
package Filter::YUICSSErrors;
use Apache2::Filter;
use base "Apache2::Filter";

use strict;
use warnings;
use Apache2::Const -compile => qw(OK);
use constant BUFF_LEN => 1024;

sub handler {
      my $f = shift;
  
      my $leftover = $f->ctx;
      while ($f->read(my $buffer, BUFF_LEN)) {
          $buffer = $leftover . $buffer if defined $leftover;
          $leftover = undef;
          while ($buffer =~ /([^\r\n]*)([\r\n]*)/g) {
              $leftover = $1, last unless $2;
              my $line = $1;
              my $spacing = $2;
              $line =~ s/<link\shref="\/extras\/yui\/build\/calendar\/assets\/skins\/sam\/calendar\.css"\srel="stylesheet"\smedia="all"\stype="text\/css"\s\/>/<link rel="stylesheet" href="\/kalender\/zoek.css" type="text\/css" \/>\n<link rel="stylesheet" href="\/kalender\/zoekyui.css" type="text\/css" \/>\n<!--[if lte IE 7]>\n<link rel="stylesheet" href="\/kalender\/zoekyui-lte-ie7.css" type="text\/css" \/>\n<![endif]-->\n<!--[if lte IE 6]>\n<link rel="stylesheet" href="\/kalender\/zoekyui-lte-ie6.css" type="text\/css" \/>\n<![endif]-->\n/ if $line;
              if($spacing) { 
                $f->print($line, $spacing) 
              } else { 
                $f->print($line) 
              };
          }
      }
  
      if ($f->seen_eos) {
          if(defined $leftover) {
              $leftover =~ s/<link\shref="\/extras\/yui\/build\/calendar\/assets\/skins\/sam\/calendar\.css"\srel="stylesheet"\smedia="all"\stype="text\/css"\s\/>/<link rel="stylesheet" href="\/kalender\/zoek.css" type="text\/css" \/>\n<link rel="stylesheet" href="\/kalender\/zoekyui.css" type="text\/css" \/>\n<!--[if lte IE 7]>\n<link rel="stylesheet" href="\/kalender\/zoekyui-lte-ie7.css" type="text\/css" \/>\n<![endif]-->\n<!--[if lte IE 6]>\n<link rel="stylesheet" href="\/kalender\/zoekyui-lte-ie6.css" type="text\/css" \/>\n<![endif]-->\n/;
              $f->print($leftover);
	  }
      }
      else {
          $f->ctx($leftover) if defined $leftover;
      }
  
      return Apache2::Const::OK;
  }
1;
