#
# Resource tests.
#
# For a detailed description of the tests format, see comments in
# file t/api_Resource.t.
#
[   {   titol   => 'LlistaDeRecursosBuida',
        op      => 'GET',
        uri     => sub {'/resource'},
        sortida => {
            status => HTTP_OK . ' ' . status_message(HTTP_OK),
        }
    },
    {   titol => 'ConsultaRecursInexistent',
        op  => 'GET',
        uri => sub { '/resource/123456789'},
        sortida => {
            status => HTTP_NOT_FOUND . ' ' . status_message(HTTP_NOT_FOUND),
        }
    },
    {   titol   => 'CreaRecurs',
        op      => 'POST',
        uri     => sub {'/resource'},
        entrada => {
            description => 'aula',
            info        => 'resource info',
        },
        sortida => {
            status  => HTTP_CREATED . ' ' . status_message(HTTP_CREATED),
            headers => { Location => \&generated_resource_id },
        },
    },
    {
        titol => 'CreaRecursDuplicat',
        op      => 'POST',
        uri     => sub {'/resource'},
        entrada => {
            description => 'aula', # resource 'aula' already exists (see previous test)
            info        => 'resource info',
        },
        sortida => {
            status  => HTTP_CONFLICT . ' ' . status_message(HTTP_CONFLICT),
        },        
    },
    {   titol   => 'ConsultaRecurs',
        op      => 'GET',
        uri     => \&generated_uri,
        entrada => {},
        sortida => {
            status  => HTTP_OK . ' ' . status_message(HTTP_OK),
            headers => {},
            body    => { description => 'aula', info => 'resource info' },
        }
    },

    {   titol   => 'ModificaRecurs',
        op      => 'PUT',
        uri     => \&generated_uri,
        entrada => {
            description => 'aula (modif)',
            info        => 'resource info (modif)',
        },
        sortida => {
            status  => HTTP_OK . ' ' . status_message(HTTP_OK),
            headers => {},
        }
    }
]
