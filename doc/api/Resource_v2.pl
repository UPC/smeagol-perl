#
# Resource tests.
# Each test has the following key/value pairs:
#
#   title  => a descriptive test description
#   op => the HTTP method to use (GET, POST, PUT, DELETE)
#   id     => the resource id   (required only when using GET, PUT or DELETE)
#   input   => a hash describing a resource (required in POST)
#   status => a code reference which to the routine used to verify
#             HTTP status response
#   new_ids => number of IDs the test should generate (1 for POST, 0 elsewhere)
#   output => a (possibly empty) list of hashes describing the object(s) returned by the server
#
[   {   title  => 'LlistaDeRecursosBuida',
        op     => 'GET',
        status => sub { shift->code == HTTP_OK },
        output => [],
    },
    {   title => 'ConsultaRecursInexistent',
        op    => 'GET',
        id    => 123456789,                    # non-existent resource ID
        status => sub { shift->code == HTTP_NOT_FOUND },
        output => [],
    },
    {   title => 'CreaRecurs',
        op    => 'POST',
        input => {
            description => 'aula',
            info        => 'resource info',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        output  => [],
    },
    {   title  => 'LlistaDeRecursosNoBuida',
        op     => 'GET',
        status => sub { shift->code == HTTP_OK },
        output => [
            {   "id"          => \&get_generated_id,
                "description" => "aula",
                "info"        => "resource info"
            }
        ],
    },
    {   title  => 'ConsultaRecurs',
        op     => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        output => {
            id          => \&get_generated_id,
            description => 'aula',
            info        => 'resource info',
        }
    },
    {   title => 'CreaRecursDuplicat',
        op    => 'POST',
        input => {
            description => 'aula',
            info        => 'una altra info',
        },
        status => sub { shift->code == HTTP_CONFLICT },
        output => [],
    },
    {   title => 'CreaRecursDescripcioMassaCurta',
        op    => 'POST',
        input => {
            description => '',
            info        => 'una altra info',
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        output => [],
    },
    {   title => 'CreaRecursDescripcioMassaLlarga',
        op    => 'POST',
        input => {
            description => 'a' x 129,    # max description length is 128 chars
            info => 'una altra info',
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        output => [],
    },
    {   title => 'CreaRecursInfoBuida',
        op    => 'POST',
        input => {
            description => 'aula amb info buida',
            info        => '',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        output  => [],
    },
    {   title  => 'ConsultaRecursInfoBuida',
        op     => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        output => {
            id          => \&get_generated_id,
            description => 'aula amb info buida',
            info        => '',
        }
    },
    {   title => 'CreaRecursInfoMassaLlarga',
        op    => 'POST',
        input => {
            description => 'un recurs',
            info        => 'a' x 257,     # max info length is 256 chars
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        output => [],
    },
    {   title => 'CreaRecursDescripcioEnBlanc',
        op    => 'POST',
        input => {
            description => '   ',       # should not accept blank descriptions
            info        => 'una info',
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        output => [],
    },
    {   title => 'ModificaRecursInexistent',
        op    => 'PUT',
        id    => 12345,
        input => {
            description => 'aula (modif)',
            info        => 'resource info (modif)',
        },
        status => sub { shift->code == HTTP_NOT_FOUND },
        output => [],
    },
    {   title => 'ModificaRecurs',
        op    => 'PUT',
        id    => \&get_generated_id,
        input => {
            description => 'aula (modif)',
            info        => 'resource info (modif)',
        },
        status => sub { shift->code == HTTP_OK },
    },
    {   title  => 'ConsultaRecursModificat',
        op     => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        output => {
            id          => \&get_generated_id,
            description => 'aula (modif)',
            info        => 'resource info (modif)',
        }
    },
    {   title => 'ModificaRecursMateixaDescripcio',
        op    => 'PUT',
        id    => \&get_generated_id,
        input => {
            description => 'aula (modif)',
            info        => 'resource info (modif) again',
        },
        status => sub { shift->code == HTTP_OK },
    },
    {   title  => 'ConsultaRecursModificatMateixaDescripcio',
        op     => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        output => {
            id          => \&get_generated_id,
            description => 'aula (modif)',
            info        => 'resource info (modif) again',
        }
    },
    {   title => 'NoModificaRecurs',    # prova de PUT idempotent
        op    => 'PUT',
        id    => \&get_generated_id,
        input => {
            description => 'aula (modif)',
            info        => 'resource info (modif) again',
        },
        status => sub { shift->code == HTTP_OK },
    },
    {   title  => 'ConsultaRecursNoModificat',
        op     => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        output => {
            id          => \&get_generated_id,
            description => 'aula (modif)',
            info        => 'resource info (modif) again',
        }
    },
    {   title  => 'EsborraRecursInexistent',
        op     => 'DELETE',
        id     => 12345,
        status => sub { shift->code == HTTP_NOT_FOUND },
        output => [],
    },
    {   title  => 'EsborraRecurs',
        op     => 'DELETE',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_OK },
        output => [],
    },
    {   title  => 'ConsultaRecursEsborrat',
        op     => 'GET',
        id     => \&get_generated_id,
        status => sub { shift->code == HTTP_NOT_FOUND },
        output => [],
    },

 #
 # The 3 following tests work together to check server does not allow updating
 # a resource description if there is already another resource with the same
 # description
 #
    {   title => 'CreaRecursPerConflicteActualitzacio_1',
        op    => 'POST',
        input => {
            description => 'r1',
            info        => 'r1 info',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        output  => [],
    },
    {   title => 'CreaRecursPerConflicteActualitzacio_2',
        op    => 'POST',
        input => {
            description => 'r2',
            info        => 'r2 info',
        },
        status  => sub { shift->code == HTTP_CREATED },
        new_ids => 1,
        output  => [],
    },
    {   title => 'ModificaRecursConflicteActualitzacio',
        op    => 'PUT',
        id    => \&get_generated_id,
        input => {
            description => 'r1',    # trying to update r2 with r1's desc
            info => 'r2 info (updated)',
        },
        status => sub { shift->code == HTTP_CONFLICT },
        output => [],
    },
    {   title => 'ModificaRecursAmbDescripcioNoValida',
        op    => 'PUT',
        id    => \&get_generated_id,
        input => {
            description => '   ',
            info        => 'r2 info (updated)',
        },
        status => sub { shift->code == HTTP_BAD_REQUEST },
        output => [],
    },
]
