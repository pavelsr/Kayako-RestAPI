#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Slurp;

BEGIN { use_ok('Kayako::RestAPI'); }

my $api_params = { 
  "api_url" => 'http://kayako.example.com/api/index.php?',
  "api_key" => '123',
  "secret_key" => '456'
};

my $module_params = {
    content_key => 'text', 
    pretty => 1, 
    attribute_prefix => 'attr_' 
};

my $kayako_api = Kayako::RestAPI->new($api_params, $module_params);

subtest "_prepare_request" => sub {

    my $r = $kayako_api->_prepare_request;

    is $r->{'apikey'}, $api_params->{'api_key'}, "Request has api key";
    ok $r->{'signature'},  "Request has signature";
    ok $r->{'salt'},  "Request has salt";
    is length $r->{'salt'}, 10, "Salt length is 10";

};

subtest "filter_fields" => sub {

    my $a = [
        {
            'title' => { text => 'In progress' },
            'id' => => { text => 1 },
            'foo' => { text => 'bar' }
        },
        {
            'title' => { text => 'Closed' },
            'id' => { text => 3 },
            'foo' => { text => 'baz' }
        }
    ];
        
    my $b = [
        {
            'title' => 'In progress',
            'id' => 1,
        },
        {
            'title' => 'Closed',
            'id' => 3,
        }
    ];

    is_deeply $kayako_api->filter_fields($a), $b, 'filter_fields is working as expected';

};

local *Kayako::RestAPI::_query = sub {
    my ($self, $method, $route, $params) = @_;
    my $samples = Kayako::RestAPI::_samples();
    my $sample = ( grep { $_->{method} eq $method && $_->{route} =~ $route } @$samples )[0]->{sample_file};
    return read_file( 't/lib/Kayako/samples/'.$sample ) ;
};

use Data::Dumper;

subtest "get_departements" => sub {
    my $res = $kayako_api->get_departements;
    is ref($res), 'ARRAY', 'return array';
    ok defined $res->[0]->{id}, 'element has id key';
    ok defined $res->[0]->{title}, 'element has title key';
    ok defined $res->[0]->{module}, 'element has module key';
    my $expected = [
          {
            'title' => 'Hard drives department',
            'id' => '5',
            'module' => 'tickets'
          },
          {
            'title' => 'Flash drives department',
            'module' => 'tickets',
            'id' => '6'
          },
          {
            'title' => 'RAID',
            'id' => '13',
            'module' => 'tickets'
          },
          {
            'title' => 'RAID',
            'module' => 'livechat',
            'id' => '14'
          }
        ];
    is_deeply $res, $expected, 'data is same as expected'
};

subtest "get_ticket_statuses" => sub {
    my $res = $kayako_api->get_ticket_statuses;
    is ref($res), 'ARRAY', 'return array';
    ok defined $res->[0]->{id}, 'element has id key';
    ok defined $res->[0]->{title}, 'element has title key';
    my $expected = [
          {
            'id' => '1',
            'title' => 'In progress'
          },
          {
            'title' => 'Closed',
            'id' => '3'
          },
          {
            'title' => 'New',
            'id' => '4'
          },
          {
            'title' => 'Awaiting reply from customer',
            'id' => '9'
          },
          {
            'title' => 'Candidate for close',
            'id' => '10'
          },
          {
            'id' => '11',
            'title' => 'Awaiting new feature'
          }
        ];
    is_deeply $res, $expected, 'data is same as expected'
};

subtest "get_ticket_priorities" => sub {
    my $res = $kayako_api->get_ticket_priorities;
    is ref($res), 'ARRAY', 'return array';
    ok defined $res->[0]->{id}, 'element has id key';
    ok defined $res->[0]->{title}, 'element has title key';
    my $expected = [
          {
            'id' => '1',
            'title' => 'Normal'
          },
          {
            'title' => 'Urgent',
            'id' => '3'
          },
          {
            'id' => '6',
            'title' => 'CRITICAL'
          }
        ];
    is_deeply $res, $expected, 'data is same as expected';
};

subtest "get_ticket_types" => sub {
    my $res = $kayako_api->get_ticket_types;
    is ref($res), 'ARRAY', 'return array';
    ok defined $res->[0]->{id}, 'element has id key';
    ok defined $res->[0]->{title}, 'element has title key';
    my $expected = [
          {
            'id' => '1',
            'title' => 'Case'
          },
          {
            'title' => 'Bug',
            'id' => '3'
          },
          {
            'title' => 'Feedback',
            'id' => '5'
          }
        ];
    is_deeply $res, $expected, 'data is same as expected';
};

subtest "get_staff" => sub {
    my $res = $kayako_api->get_staff;
    is ref($res), 'ARRAY', 'return array';
    
    ok defined $res->[0]->{id}, 'element has id key';
    ok defined $res->[0]->{lastname}, 'element has lastname key';
    ok defined $res->[0]->{fullname}, 'element has fullname key';
    ok defined $res->[0]->{email}, 'element has email key';
    
    ok defined $res->[0]->{id}{ $module_params->{content_key} };
    ok defined $res->[0]->{lastname}{ $module_params->{content_key} };
    ok defined $res->[0]->{fullname}{ $module_params->{content_key} };
    ok defined $res->[0]->{email}{ $module_params->{content_key} };
    
};

use Data::Dumper;
subtest "get_ticket_hash" => sub {
    
    my @keys = qw/
        statusid 
        lastactivity 
        lastuserreply
        userorganization
        templategroupid
        templategroupname
        posts
        userid
        laststaffreply
        ownerstaffid
        creator
        nextreplydue
        creationmode
        departmentid
        fullname
        note
        ipaddress
        slaplanid
        replies
        priorityid
        tags
        attr_id
        typeid
        attr_flagtype
        ownerstaffname
        escalationruleid
        creationtype
        email
        isescalated
        subject
        userorganizationid
        resolutiondue
        displayid
        creationtime
        lastreplier
    /;
    my $res = $kayako_api->get_ticket_hash(1000);
    for my $k (@keys) {
        ok defined $res->{$k}, "element has $k key";
    }
};

done_testing;