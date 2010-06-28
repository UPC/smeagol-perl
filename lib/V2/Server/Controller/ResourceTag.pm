package V2::Server::Controller::ResourceTag;
use Moose;
use namespace::autoclean;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

V2::Server::Controller::ResourceTag - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub default : Local : ActionClass('REST') {
  
}

sub default_GET {
  my ( $self, $c, $res, $tag ) = @_;
  
  if($tag){
    my @resource_tag = $c->model('DB::ResourceTag')->search({tag_id=>$tag});
    my @resources;
    my $resource_aux;
    my @resource;

if (@resource_tag){	
    
    foreach (@resource_tag) {
      $resource_aux = $c->model('DB::Resource')->find({id=>$_->resource_id});
      
      my  @resource = {
	    id => $resource_aux->id,
	    description => $resource_aux->description,
	    info => $resource_aux->info,
	    tags => $resource_aux->tag_list,
      }; 

      push (@resources, @resource);
      
    }
      
      $c->stash->{content}=\@resources;
      $c->response->status(200);
      $c->forward( $c->view('JSON') ); 
}else{
      $c->stash->{template}='not_found.tt';
      $c->response->status(404);
      $c->forward( $c->view('TT') ); 	

}   
    
  }else{
    $c->response->redirect('/resource');  
  }   
}

sub default_POST {
}

sub default_PUT {
}

sub default_DELETE {
}

=head1 AUTHOR

Jordi Amorós Andreu,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
