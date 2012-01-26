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
[   {   title  => 'LlistaDeRecursosBuida',
        method => 'GET',
        status => sub { shift->code == HTTP_OK },
        result => [],
    },
    {   title  => 'ConsultaRecursInexistent',
        method => 'GET',
        id     => 123456789,                    # non-existent resource ID
        status => sub { shift->code == HTTP_NOT_FOUND },
    },
    {   title  => 'CreaRecurs',
        method => 'POST',
        args   => {
            description => 'aula',
            info        => 'resource info',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
    },
    {   title  => 'ConsultaRecurs',
        method => 'GET',
        id     => 1,
        status => sub { shift->code == HTTP_OK },
        result => {
            id          => 1,
            description => 'aula',
            info        => 'resource info',
            }

    },

    #    {   title  => 'ModificaRecurs',
    #        method => 'PUT',
    #        id     => get_generated_resource_id(),
    #        args   => {
    #            description => 'aula (modif)',
    #            info        => 'resource info (modif)',
    #        },
    #        sortida => {
    #            status  => HTTP_OK . ' ' . status_message(HTTP_OK),
    #            headers => {},
    #        }
    #    }
]
