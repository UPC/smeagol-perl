[
    {   title  => 'CreaRecurs',
        url    => { type => 'resource' },
        method => 'POST',
        args   => {
            description => 'aula',
            info        => 'resource info',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        result  => [],
    },
#    {
#        title => 'GetResourceTags'
#        url   => { type => 'resource', id => \&get_generated_id },
#        method => 'GET',
#        status => sub { shift ->code == HTTP_OK },
#        result => [],
#    }
]
