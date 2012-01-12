#
# Resource tests.
# Each test has the following key/value pairs:
#
#   title  => a descriptive test description
#   method => the HTTP method to use (GET, POST, PUT, DELETE)
#   id     => the resource id   (required only when using GET, PUT or DELETE)
#   args   => a hash describing a resource (required in POST)
#   status => a code reference which to the routine used to verify 
#             HTTP status response
#   new_ids => number of IDs the test should generate (1 for POST, 0 elsewhere)
#   result => a hash describing the object(s) returned by the server
#
[   {   title   => 'LlistaDeRecursosBuida',
        method  => 'GET',
        #id      => undef,
        #args    => undef,
        status  => sub { shift->code == HTTP_OK },
        #new_ids => 0,
        result => [],
    },
    {   title   => 'ConsultaRecursInexistent',
        method  => 'GET',
        id      => 123456789, # non-existent resource ID
        #args    => undef,
        status  => sub { shift->code == HTTP_NOT_FOUND },
        #new_ids => 0,
        #result  => [],
    },
#    {   title   => 'CreaRecurs',
#        method  => 'POST',
#       uri     => sub {'/resource'},
#        entrada => {
#            description => 'aula',
#            info        => 'resource info',
#        },
#        sortida => {
#            status  => HTTP_CREATED . ' ' . status_message(HTTP_CREATED),
#            headers => { Location => \&generated_resource_id },
#        },
#    },
#    {
#        titol => 'CreaRecursDuplicat',
#        op      => 'POST',
#        uri     => sub {'/resource'},
#        entrada => {
#            description => 'aula', # resource 'aula' already exists (see previous test)
#            info        => 'resource info',
#        },
#        sortida => {
#            status  => HTTP_CONFLICT . ' ' . status_message(HTTP_CONFLICT),
#        },        
#    },
#    {   titol   => 'ConsultaRecurs',
#        op      => 'GET',
#        uri     => \&generated_uri,
#        entrada => {},
#        sortida => {
#            status  => HTTP_OK . ' ' . status_message(HTTP_OK),
#            headers => {},
#            body    => { description => 'aula', info => 'resource info' },
#        }
#    },

#    {   titol   => 'ModificaRecurs',
#        op      => 'PUT',
#        uri     => \&generated_uri,
#        entrada => {
#            description => 'aula (modif)',
#            info        => 'resource info (modif)',
#        },
#        sortida => {
#            status  => HTTP_OK . ' ' . status_message(HTTP_OK),
#            headers => {},
#        }
#    }
]
