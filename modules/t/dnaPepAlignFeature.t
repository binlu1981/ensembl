
use lib 't';

BEGIN { $| = 1;  
	use Test;
	plan tests => 39;
}

use MultiTestDB;
use Bio::EnsEMBL::DnaPepAlignFeature;
use Bio::EnsEMBL::SeqFeature;
use Bio::EnsEMBL::RawContig;

use TestUtils qw ( debug test_getter_setter );

# switch on the debug prints

our $verbose = 0;

my($CHR, $START, $END) =  ('20', 30_363_615, 30_475_000);
my $CTG_BOUNDARY       =  62877;

#
# 1 Test DnaPepAlignFeature compiles
#
ok(1);

my $multi_db = MultiTestDB->new;
my $db = $multi_db->get_DBAdaptor('core');



my $slice = $db->get_SliceAdaptor->fetch_by_chr_start_end($CHR,$START,$END);

my $contig = new Bio::EnsEMBL::RawContig;
$contig->seq('ACTGACTG');
$contig->name('bogus contig');

my @feats;
my $fp = new Bio::EnsEMBL::FeaturePair;
$fp->start(5);
$fp->end  (7);
$fp->strand(1);
$fp->score(10);
$fp->contig($contig);
$fp->hstart(105);
$fp->hend    (105);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');

push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start(11);
$fp->end  (16);
$fp->strand(1);
$fp->score(10);
$fp->contig($contig);
$fp->hstart  (106);
$fp->hend    (107);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

#
#
# 2 Test DnaPepAlignFeature::new(-features)
#
$dnaf = Bio::EnsEMBL::DnaPepAlignFeature->new( -features => \@feats );
ok($dnaf && $dnaf->validate);

#
# 3 Test DnaPepAlignFeature::seqname
#
ok($dnaf->seqname eq 'bogus contig');

#
# 4 Test DnaPepAlignFeature::hseqname
#
ok($dnaf->hseqname eq 'dummy-hid');


#
# 5 Test DnaPepAlignFeature::cigar_string
#
ok($dnaf->cigar_string =~ '3M3I6M');

#
# 6-8 Test DnaPepAlignFeature::reverse_complement
#
my $strand = $dnaf->strand;
my $hstrand = $dnaf->hstrand;
$dnaf->reverse_complement;
ok($dnaf->cigar_string =~ '6M3I3M');
ok(($strand*-1) == $dnaf->strand);
ok(($hstrand*-1) == $dnaf->hstrand); 



#
# 9 Test DnaPepAlignFeature::start
#
ok($dnaf->start == 5);

#
# 10 Test DnaPepAlignFeature::end
#
ok($dnaf->end == 16);

#
# 11 Test DnaPepAlignFeature::ungapped_features
#
ok( scalar($dnaf->ungapped_features) == 2);


#
# 12 Test retrieval from database
#
my $features = $slice->get_all_ProteinAlignFeatures;

ok(scalar @$features);

#
# 13 Test transformation to raw contig
#
my $f = $features->[0];
my @fs = $f->transform;
ok( scalar @fs );

#
# 14 Test transformation back to slice
#
($f) = @fs;
$f = $f->transform($slice); 
ok($f);

#
# 15 Test transformation onto negative strand slice
#
$f = $f->transform($slice->invert);
ok($f);


#
# 16-21 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (+ve strand, +ve hitstrand)
#
@feats = ();
$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 5);
$fp->end  ($CTG_BOUNDARY );
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart(104);
$fp->hend  (105);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 4);
$fp->end  ($CTG_BOUNDARY + 9);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (106);
$fp->hend    (107);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 10);
$fp->end  ($CTG_BOUNDARY + 12);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (110);
$fp->hend    (110);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$dnaf = Bio::EnsEMBL::DnaPepAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '6M3I6M6D3M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);




#
# 22-27 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (-ve strand, +ve hitstrand)
#
@feats = ();

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 8);
$fp->end  ($CTG_BOUNDARY + 10);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (100);
$fp->hend    (100);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 1);
$fp->end  ($CTG_BOUNDARY + 4);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart(101);
$fp->hend    (102);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 4);
$fp->end  ($CTG_BOUNDARY - 2);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart  (105);
$fp->hend    (105);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);


$dnaf = Bio::EnsEMBL::DnaPepAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M3I6M6D3M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);

debug( "Feature 0 dump" );
while( my ($k, $v) = each %{$dnafs[0]} ) {
  debug( "  ->".$k." = ".$v );
}

ok($dnafs[0]->validate || 1); 

debug( "Feature 1 dump" );
while( my ($k, $v) = each %{$dnafs[1]} ) {
  debug( "  ->".$k." = ".$v );
}
ok($dnafs[1]->validate || 1);




#
#
# Do the same tests again on the negative strand slice
#
#
$CTG_BOUNDARY = $slice->length - $CTG_BOUNDARY + 1;
$slice = $slice->invert;



#
# 28-33 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (+ve strand, +ve hitstrand)
#
@feats = ();
$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 2);
$fp->end  ($CTG_BOUNDARY);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart(105);
$fp->hend  (105);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 4);
$fp->end  ($CTG_BOUNDARY + 9);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (106);
$fp->hend    (107);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 10);
$fp->end  ($CTG_BOUNDARY + 12);
$fp->strand(1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (110);
$fp->hend    (110);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$dnaf = Bio::EnsEMBL::DnaPepAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M3I6M6D3M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);



#
# 34-39 create a dnaalign feature on a slice across a contig boundary
#       and convert to raw contig coordinates
#       (-ve strand, +ve hitstrand)
#
@feats = ();

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY + 8);
$fp->end  ($CTG_BOUNDARY + 10);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart  (100);
$fp->hend    (100);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 1);
$fp->end  ($CTG_BOUNDARY + 4);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->hstart(101);
$fp->hend    (102);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);

$fp = new Bio::EnsEMBL::FeaturePair;
$fp->start($CTG_BOUNDARY - 4);
$fp->end  ($CTG_BOUNDARY - 2);
$fp->strand(-1);
$fp->score(10);
$fp->contig($slice);
$fp->seqname(1);
$fp->hstart  (105);
$fp->hend    (105);
$fp->hstrand (1);
$fp->hseqname('dummy-hid');
push(@feats,$fp);


$dnaf = Bio::EnsEMBL::DnaPepAlignFeature->new( -features => \@feats );
ok($dnaf);
ok($dnaf->cigar_string eq '3M3I6M6D3M');
ok($dnaf->validate || 1); #validate doesn't return true but throws on fail

@dnafs = $dnaf->transform;
ok(scalar(@dnafs) == 2);
ok($dnafs[0]->validate || 1); 
ok($dnafs[1]->validate || 1);



