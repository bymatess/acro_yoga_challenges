#!/usr/bin/env perl
use Dancer;
# general routes: "/", hooks
use User::App;
# before hook, login, logout, registration, confirmation, profile (show, edit), photo (show, upload), change password
use User::User;
# for uploading photos and videos
use User::Upload;
# position related 
use User::Position;
# methods - no routes
use User::Helpers;
dance;
