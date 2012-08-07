package Bio::EnsEMBL::Pipeline::Production::GeneCount;

use strict;
use warnings;

use base qw/Bio::EnsEMBL::Pipeline::Production::StatsGenerator/;


sub get_attrib_codes {
  my ($self) = @_;
  my @attrib_codes = ('coding_cnt', 'pseudogene_cnt', 'noncoding_cnt');
  my %biotypes;
  foreach my $code (@attrib_codes) {
    my ($group) = $code =~ /(\w+)\_cnt/;
    my $biotypes = $self->get_biotype_group($group);
    $biotypes{$code} = $biotypes;
  }
  return %biotypes;
}

sub get_total {
  my ($self) = @_;
  my $species = $self->param('species');
  my $total = scalar(@{ Bio::EnsEMBL::Registry->get_adaptor($species, 'core', 'gene')->fetch_all });
  return $total;
}


sub get_feature_count {
  my ($self, $slice, $key, $biotypes) = @_;
  my $count = 0;
  foreach my $biotype (@$biotypes) {
    $count += scalar(@{ $slice->get_all_Genes_by_type($biotype) });
  }
  return $count;
}


1;

