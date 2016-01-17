package Pod::Weaver::Role::SortSections;

# DATE
# VERSION

use 5.010001;
use Moose::Role;

use Pod::Elemental::Element::Nested;
use Sort::BySpec qw(sort_by_spec);

sub sort_sections {
    my ($self, $document, $spec) = @_;

    # cluster document's top-level children into clusters of headlines, where
    # the first element of each cluster is a head1. we are going to sort the
    # clusters later.
    my @clusters;
    my @pre_clusters; # store elements before the first cluster

    {
        my $i = -1;
        my $children = $document->children;

        while ($i < $#{$children}) {
            $i++;
            my $is_h1 = $children->[$i]->can('command')
                && $children->[$i]->command eq 'head1';
            if ($is_h1) {
                push @clusters, [$children->[$i]];
            } else {
                if (@clusters) {
                    push @{$clusters[-1]}, $children->[$i];
                } else {
                    push @pre_clusters, $children->[$i];
                }
            }
        }
    }

    my $sorter = sort_by_spec(
        spec => $spec,
        xform => sub {shift->[0]{content}},
    );
    @clusters = $sorter->(@clusters);
    $document->children([ @pre_clusters, (map { @$_ } @clusters) ]);
}

no Moose::Role;
1;
# ABSTRACT: Sort POD sections

=head1 SYNOPSIS

In your L<Pod::Weaver> plugin:

 $self->sort_sections($document, [
     'NAME',
     'VERSION',
     'DESCRIPTION',
     qr/.+/, # put everything else here

     'AUTHOR',
     'COPYRIGHT AND LICENSE',
     'COPYRIGHT', # sometimes C&L is separated
     'LICENSE',   # sometimes C&L is separated

     'SEE ALSO',
 ]);


=head1 DESCRIPTION

As we add sections to document using various plugins or section modules,
sometimes in different orders, the result is that the order of sections might
not be like we want. This role provides a C<sort_sections()> to rectify that.
This should be done after all section adding.


=head1 METHODS

=head2 $obj->sort_sections($document, $spec)

Sort POD sections. C<$spec> is a list of section names or regexes as specified
in L<Sort::BySpec>.


=head1 SEE ALSO

L<Sort::BySpec>
