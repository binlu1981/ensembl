# EnsEMBL module for Transcript
# Copyright EMBL-EBI/Sanger center 2002
#
# Cared for by Arne Stabenau
#
#
# You may distribute this module under the same terms as perl itself

# POD documentation - main docs before the code

=head1 NAME

PredictionTranscript

=head1 SYNOPSIS


=head1 DESCRIPTION

Container for single transcript ab initio gene prediction ala GenScan or SNAP.
Is directly storable/retrievable in EnsEMBL using PredictionTranscript Adaptor.

Creation:

     my $tran = new Bio::EnsEMBL::PredictionTranscript();
     $tran->add_Exon( $exon );

     my $tran = new Bio::EnsEMBL::PredictionTranscript(@exons);

     The order of the exons has to be right, as PT cant judge how to sort them.
     ( no sort as in Bio::EnsEMBL::Transcript )

     PredictionTranscript is geared towards the partial retrieve case from db.
     Exons can be missing in the middle. For storage though its necessary to 
     have them all and in contig coord system. 

Manipulation:

     # Returns an array of Exon objects, might contain undef instead of exon.
     my @exons = @{$tran->get_all_Exons};  

     # Returns the peptide translation as string 
     my $pep   = $tran->translate;

     # phase padded Exons cdna sequence. Phases usually match.
     my $cdna = $trans->get_cdna() 


=head1 CONTACT

contact EnsEMBL dev <ensembl-dev@ebi.ac.uk> for information

=cut

package Bio::EnsEMBL::PredictionTranscript;
use vars qw(@ISA);
use strict;

use Bio::EnsEMBL::Feature;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::Translation;

@ISA = qw(Bio::EnsEMBL::Transcript);



=head2 coding_region_start

  Arg [1]    : none
  Example    : $coding_region_start = $pt->coding_region_start
  Description: Retrieves the start of the coding region of this transcript in
               slice coordinates.  For prediction transcripts this
               is always the start of the transcript (i.e. there is no UTR).
               By convention, the coding_region_start is always lower than
               the value returned by the coding_end method.
               The value returned by this function is NOT the biological
               coding start since on the reverse strand the biological coding
               start would be the higher genomic value.
  Returntype : int
  Exceptions : none
  Caller     : general

=cut

sub coding_region_start {
  my $self = shift;
  return $self->start();
}


=head2 coding_region_end

  Arg [1]    : none
  Example    : $coding_region_end = $transcript->coding_region_end
  Description: Retrieves the start of the coding region of this prediction
               transcript. For prediction transcripts this is always the same
               as the end since no UTRs are stored.
               By convention, the coding_region_end is always higher than the
               value returned by the coding_region_start method.
               The value returned by this function is NOT the biological
               coding start since on the reverse strand the biological coding
               end would be the lower genomic value.
  Returntype : int
  Exceptions : none
  Caller     : general

=cut

sub coding_region_end {
  my $self = shift;
  return $self->end();
}



=head2 get_all_translateable_Exons

  Arg [1]    : none
  Example    : $exons = $self->get_all_translateable_Exons
  Description: Retrieves the translateable portion of all exons in this
               transcript.  For prediction transcripts this means all exons
               since no UTRs are stored for them.
  Returntype : listref of Bio::EnsEMBL::PredictionExons
  Exceptions : none
  Caller     : general

=cut

sub get_all_translateable_Exons {
  my $self = shift;
  return $self->get_all_Exons();
}



=head2 stable_id

  Arg [1]    : none
  Example    : print $pt->stable_id();
  Description: Gets a 'stable' identifier for this prediction transcript.  Note
               that prediction transcripts do not have real stable
               identifiers (i.e. identifiers maintained between releases and
               stored in the database) and this method is provided to be
               polymorphic with the Transcript class.
               The stable identifer returned returned is formed by concating
               the logic-name of the prediction transcripts analysis with
               the transcripts  dbID (0 Left padded to 11digits).
  Returntype : string
  Exceptions : 
  Caller     : 

=cut

sub stable_id {
  my $self = shift;

  my $analysis = $self->analysis();
  my $logic_name = uc($analysis->logic_name()) if($analysis);
  $logic_name ||= 'PTRANS';

  my $id = $self->dbID();
  my $pad = 11;
  $pad -= length($id);

  return $logic_name . ('0' x $pad) . $id;
}


sub get_all_DBEntries { return []; }

sub get_all_DBLinks { return []; }

sub add_DBEntry {}

sub external_db { return undef; }

sub external_status { return undef; }

sub external_name { return undef; }

sub is_known { return 0;}


=head2 translation

  Arg [1]    : none
  Example    : $translation = $pt->translation();
  Description: Retrieves a Bio::EnsEMBL::Translation object for this prediction
               transcript.  Note that this translation is generated on the fly
               and is not stored in the database.  The translation always
               spans the entire transcript (no UTRs; all CDS) and does not
               have an associated dbID, stable_id or adaptor.
  Returntype : int
  Exceptions : none
  Caller     : general

=cut

sub translation {
  my $self = shift;

  #calculate translation on the fly
  my $strand = $self->strand();

  my $start_exon;
  my $end_exon;

  my @exons = @{$self->get_all_Exons()};

  return undef if(!@exons);

  if($strand == 1) {
    $start_exon = $exons[0];
    $end_exon = $exons[-1];
  } else {
    $start_exon = $exons[-1];
    $end_exon = $exons[0];
  }

  return
    Bio::EnsEMBL::Translation->new(-START_EXON => $start_exon,
                                   -END_EXON   => $end_exon,
                                   -SEQ_START  => 1,
                                   -SEQ_END    => $end_exon->length());
}



=head2 translate

  Args      : none
  Function  : Give a peptide translation of all exons currently in
              the PT. Gives empty string when none is in.
  Returntype: a Bio::Seq as in transcript->translate()
  Exceptions: none
  Caller    : general

=cut


sub translate {
  my ($self) = @_;

  my $dna = $self->translateable_seq();
  $dna    =~ s/TAG$|TGA$|TAA$//i;
  # the above line will remove the final stop codon from the mrna
  # sequence produced if it is present, this is so any peptide produced
  # won't have a terminal stop codon
  # if you want to have a terminal stop codon either comment this line out
  # or call translatable seq directly and produce a translation from it

  my $bioseq = new Bio::Seq( -seq => $dna, -moltype => 'dna' );

  return $bioseq->translate();
}


=head2 cdna_coding_start

  Arg [1]    : none
  Example    : $relative_coding_start = $transcript->cdna_coding_start;
  Description: Retrieves the position of the coding start of this transcript
               in cdna coordinates (relative to the start of the 5prime end of
               the transcript, excluding introns, including utrs). This is
               always 1 for prediction transcripts because they have no UTRs.
  Returntype : int
  Exceptions : none
  Caller     : five_prime_utr, get_all_snps, general

=cut

sub cdna_coding_start { return 1; }



=head2 cdna_coding_end

  Arg [1]    : none
  Example    : $relative_coding_start = $transcript->cdna_coding_start;
  Description: Retrieves the position of the coding end of this transcript
               in cdna coordinates (relative to the start of the 5prime end of
               the transcript, excluding introns, including utrs). This is
               always te length of the cdna for prediction transcripts because
               they have no UTRs.
  Returntype : int
  Exceptions : none
  Caller     : five_prime_utr, get_all_snps, general

=cut

sub cdna_coding_end {
  my $self = shift;
  return length($self->spliced_seq);
}


=head2 transform

  Arg  1     : String $coordinate_system_name
  Arg [2]    : String $coordinate_system_version
  Example    : $ptrans = $ptrans->transform('chromosome', 'NCBI33');
               $ptrans = $ptrans->transform('clone');
  Description: Moves this PredictionTranscript to the given coordinate system.
               If this Transcript has Exons attached, they move as well.
               A new Transcript is returned or undefined if this PT is not
               defined in the new coordinate system.
  Returntype : Bio::EnsEMBL::PredictionTranscript
  Exceptions : wrong parameters
  Caller     : general

=cut

sub transform {
  my $self = shift;

  # catch for old style transform calls
  if( ref $_[0] && $_[0]->isa( "Bio::EnsEMBL::Slice" )) {
    throw("transform needs coordinate systems details now," .
          "please use transfer");
  }

  my $new_transcript = Bio::EnsEMBL::Feature::transform($self, @_ );
  return undef unless $new_transcript;

  #go through the _trans_exon_array so as not to prompt lazy-loading
  if(exists($self->{'_trans_exon_array'})) {
    my @new_exons;
    foreach my $old_exon ( @{$self->{'_trans_exon_array'}} ) {
      my $new_exon = $old_exon->transform(@_);
      push(@new_exons, $new_exon);
    }
    $new_transcript->{'_trans_exon_array'} = \@new_exons;
  }

  return $new_transcript;
}



=head2 transfer

  Arg  1     : Bio::EnsEMBL::Slice $destination_slice
  Example    : $ptrans = $ptrans->transfer($slice);
  Description: Moves this PredictionTranscript to the given slice.
               If this Transcripts has Exons attached, they move as well.
               If this transcript cannot be moved then undef is returned
               instead.
  Returntype : Bio::EnsEMBL::PredictionTranscript
  Exceptions : none
  Caller     : general

=cut

sub transfer {
  my $self = shift;

  my $new_transcript = $self->SUPER::transfer( @_ );
  return undef unless $new_transcript;

  if( exists $self->{'_trans_exon_array'} ) {
    my @new_exons;
    for my $old_exon ( @{$self->{'_trans_exon_array'}} ) {
      my $new_exon = $old_exon->transfer( @_ );
      push( @new_exons, $new_exon );
    }

    $new_transcript->{'_trans_exon_array'} = \@new_exons;
  }

  return $new_transcript;
}



=head2 get_exon_count

  Description: DEPRECATED - use get_all_Exons instead

=cut

sub get_exon_count {
   my $self = shift;
   deprecate('Use scalar(@{$transcript->get_all_Exon()s}) instead');
   return scalar( @{$self->get_all_Exons} );
}


=head2 set_exon_count

  Description: DEPRECATED - this method does nothing now

=cut

sub set_exon_count {
  deprecate('This method no longer does anything.');
}



=head2 get_cdna

  Description : DEPRECATED - use spliced_seq() or translateable_seq instead

=cut

sub get_cdna {
  my $self = shift;
  deprecate('use spliced_seq instead');
  return $self->spliced_seq();
}

1;
