#!/usr/bin/perl

use strict;
use warnings;

use RT::Test tests => 22;
use Encode;
my ( $baseurl, $m ) = RT::Test->started_ok;
ok $m->login, 'logged in as root';

$RT::Test::SKIP_REQUEST_WORK_AROUND = 1;

use utf8;

use File::Spec;

diag 'test without attachments' if $ENV{TEST_VERBOSE};

{
    $m->get_ok( $baseurl . '/Ticket/Create.html?Queue=1' );

    $m->form_number(3);
    $m->submit_form(
        form_number => 3,
        fields      => { Subject => '标题', Content => '测试' },
    );
    $m->content_like( qr/Ticket \d+ created/i, 'created the ticket' );
    $m->follow_link_ok( { text => 'with headers' },
        '-> /Ticket/Attachment/WithHeaders/...' );
    $m->content_contains( '标题', 'has subject 标题' );
    $m->content_contains( '测试', 'has content 测试' );

    my ( $id ) = $m->uri =~ /(\d+)$/;
    ok( $id, 'found attachment id' );
    my $attachment = RT::Attachment->new( $RT::SystemUser );

    # let make original encoding to gbk
    $attachment->AddHeader( 'X-RT-Original-Encoding' => 'gbk' );
    $m->get( $m->uri );
    $m->content_contains( '标题', 'has subject 标题' );
    $m->content_contains( '测试', 'has content 测试' );
}

diag 'test with attachemnts' if $ENV{TEST_VERBOSE};

{

    my $file =
      File::Spec->catfile( File::Spec->tmpdir, 'rt_attachemnt_abcde.txt' );
    open my $fh, '>', $file or die $!;
    binmode $fh, ':utf8';
    print $fh '附件';
    close $fh;

    $m->get_ok( $baseurl . '/Ticket/Create.html?Queue=1' );

    $m->form_number(3);
    $m->submit_form(
        form_number => 3,
        fields => { Subject => '标题', Content => '测试', Attach => $file },
    );
    $m->content_like( qr/Ticket \d+ created/i, 'created the ticket' );
    $m->follow_link_ok( { text => 'with headers' },
        '-> /Ticket/Attachment/WithHeaders/...' );

    # subject is in the parent attachment, so there is no 标题
    $m->content_lacks( '标题', 'does not have content 标题' );
    $m->content_contains( '测试', 'has content 测试' );

    my ( $id ) = $m->uri =~ /(\d+)$/;
    ok( $id, 'found attachment id' );
    my $attachment = RT::Attachment->new( $RT::SystemUser );

    # let make original encoding to gbk
    $attachment->AddHeader( 'X-RT-Original-Encoding' => 'gbk' );
    $m->get( $m->uri );
    $m->content_lacks( '标题', 'does not have content 标题' );
    $m->content_contains( '测试', 'has content 测试' );


    $m->back;
    $m->back;
    $m->follow_link_ok( { text_regex => qr/by root/ },
        '-> /Ticket/Attachment/...' );
    $m->content_contains( '附件', 'has content 附件' );

    ( $id ) = $m->uri =~ /(\d+)\D+$/;
    ok( $id, 'found attachment id' );
    $attachment = RT::Attachment->new( $RT::SystemUser );

    # let make original encoding to gbk
    $attachment->AddHeader( 'X-RT-Original-Encoding' => 'gbk' );
    $m->get( $m->uri );
    $m->content_contains( '附件', 'has content 附件' );

    unlink $file;
}

