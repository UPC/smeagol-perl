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
        result => [],
    },
    {   title  => 'CreaRecurs',
        method => 'POST',
        args   => {
            description => 'aula',
            info        => 'resource info',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        result  => [],
    },
    {   title  => 'LlistaDeRecursosNoBuida',
        method => 'GET',
        status => sub { shift->code == HTTP_OK },
        result => [
            {   "id"          => \&get_generated_id,
                "description" => "aula",
                "info"        => "resource info"
            }
        ],
    },
    {   title  => 'ConsultaRecurs',
        method => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        result => {
            id          => \&get_generated_id,
            description => 'aula',
            info        => 'resource info',
        }
    },
    {   title  => 'CreaRecursDuplicat',
        method => 'POST',
        args   => {
            description => 'aula',
            info        => 'una altra info',
        },
        status => sub { shift->code == HTTP_CONFLICT },
        result => [],
    },
    {   title  => 'CreaRecursDescripcioMassaCurta',
        method => 'POST',
        args   => {
            description => '',
            info        => 'una altra info',
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        result => [],
    },
    {   title  => 'CreaRecursDescripcioMassaLlarga',
        method => 'POST',
        args   => {
            description => 'a' x 129,    # max description length is 128 chars
            info => 'una altra info',
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        result => [],
    },
    {   title  => 'CreaRecursInfoBuida',
        method => 'POST',
        args   => {
            description => 'aula amb info buida',
            info        => '',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        result  => [],
    },
    {   title  => 'ConsultaRecursInfoBuida',
        method => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        result => {
            id          => \&get_generated_id,
            description => 'aula amb info buida',
            info        => '',
        }
    },
    {   title  => 'CreaRecursInfoMassaLlarga',
        method => 'POST',
        args   => {
            description => 'un recurs',
            info        => 'a' x 257,     # max info length is 256 chars
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        result => [],
    },
    {   title  => 'CreaRecursDescripcioEnBlanc',
        method => 'POST',
        args   => {
            description => '   ',       # should not accept blank descriptions
            info        => 'una info',
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        result => [],
    },
    {   title  => 'ModificaRecursInexistent',
        method => 'PUT',
        id     => 12345,
        args   => {
            description => 'aula (modif)',
            info        => 'resource info (modif)',
        },
        status => sub { shift->code == HTTP_NOT_FOUND },
        result => [],
    },
    {   title  => 'ModificaRecurs',
        method => 'PUT',
        id     => \&get_generated_id,
        args   => {
            description => 'aula (modif)',
            info        => 'resource info (modif)',
        },
        status => sub { shift->code == HTTP_OK },
    },
    {   title  => 'ConsultaRecursModificat',
        method => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        result => {
            id          => \&get_generated_id,
            description => 'aula (modif)',
            info        => 'resource info (modif)',
        }
    },
    {   title  => 'EsborraRecursInexistent',
        method => 'DELETE',
        id     => 12345,
        status => sub { shift->code == HTTP_NOT_FOUND },
        result => [],
    },
    {   title  => 'EsborraRecurs',
        method => 'DELETE',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        result => [],
    },
    {   title  => 'ConsultaRecursEsborrat',
        method => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_NOT_FOUND },
        result => [],
    },

 #
 # The 3 following tests work together to check server does not allow updating
 # a resource description if there is already another resource with the same
 # description
 #
    {   title  => 'CreaRecursPerConflicteActualitzacio_1',
        method => 'POST',
        args   => {
            description => 'r1',
            info        => 'r1 info',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        result  => [],
    },
    {   title  => 'CreaRecursPerConflicteActualitzacio_2',
        method => 'POST',
        args   => {
            description => 'r2',
            info        => 'r2 info',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        result  => [],
    },
    {   title  => 'ModificaRecursConflicteActualitzacio',
        method => 'PUT',
        id     => \&get_generated_id,
        args   => {
            description => 'r1',    # trying to update r2 with r1's desc
            info => 'r2 info (updated)',
        },
        status => sub { shift->code == HTTP_CONFLICT },
        result => [],
    },
    {   title  => 'ModificaRecursAmbDescripcioNoValida',
        method => 'PUT',
        id     => \&get_generated_id,
        args   => {
            description => '   ',
            info        => 'r2 info (updated)',
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        result => [],
    },
]
