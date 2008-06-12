! Copyright (C) 2006, 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: words kernel sequences namespaces assocs hashtables
definitions kernel.private classes classes.private
classes.algebra quotations arrays vocabs effects combinators ;
IN: generic

! Method combination protocol
GENERIC: perform-combination ( word combination -- )

GENERIC: make-default-method ( generic combination -- method )

PREDICATE: generic < word
    "combination" word-prop >boolean ;

M: generic definition drop f ;

: make-generic ( word -- )
    [ { "unannotated-def" } reset-props ]
    [ dup "combination" word-prop perform-combination ]
    bi ;

: method ( class generic -- method/f )
    "methods" word-prop at ;

PREDICATE: method-spec < pair
    first2 generic? swap class? and ;

: order ( generic -- seq )
    "methods" word-prop keys sort-classes ;

: specific-method ( class word -- class )
    order min-class ;

GENERIC: effective-method ( ... generic -- method )

: next-method-class ( class generic -- class/f )
    order [ class<= ] with filter reverse dup length 1 =
    [ drop f ] [ second ] if ;

: next-method ( class generic -- class/f )
    [ next-method-class ] keep method ;

GENERIC: next-method-quot* ( class generic -- quot )

: next-method-quot ( class generic -- quot )
    dup "combination" word-prop next-method-quot* ;

: (call-next-method) ( class generic -- )
    next-method-quot call ;

TUPLE: check-method class generic ;

: check-method ( class generic -- class generic )
    over class? over generic? and [
        \ check-method boa throw
    ] unless ; inline

: affected-methods ( class generic -- seq )
    "methods" word-prop swap
    [ nip [ classes-intersect? ] [ class<= ] 2bi or ] curry assoc-filter
    values ;

: update-generic ( class generic -- )
    affected-methods [ +called+ changed-definition ] each ;

: with-methods ( class generic quot -- )
    [ drop update-generic ]
    [ [ "methods" word-prop ] dip call ]
    [ drop make-generic drop ]
    3tri ; inline

: method-word-name ( class word -- string )
    word-name "/" rot word-name 3append ;

PREDICATE: method-body < word
    "method-generic" word-prop >boolean ;

M: method-body stack-effect
    "method-generic" word-prop stack-effect ;

M: method-body crossref?
    "forgotten" word-prop not ;

: method-word-props ( class generic -- assoc )
    [
        "method-generic" set
        "method-class" set
    ] H{ } make-assoc ;

: <method> ( class generic -- method )
    check-method
    [ method-word-props ] 2keep
    method-word-name f <word>
    [ set-word-props ] keep ;

: reveal-method ( method class generic -- )
    [ set-at ] with-methods ;

: create-method ( class generic -- method )
    2dup method dup [
        2nip
    ] [
        drop [ <method> dup ] 2keep reveal-method
    ] if ;

: <default-method> ( generic combination -- method )
    [ drop object bootstrap-word swap <method> ] [ make-default-method ] 2bi
    [ define ] [ drop t "default" set-word-prop ] [ drop ] 2tri ;

: define-default-method ( generic combination -- )
    dupd <default-method> "default-method" set-word-prop ;

! Definition protocol
M: method-spec where
    dup first2 method [ ] [ second ] ?if where ;

M: method-spec set-where
    first2 method set-where ;

M: method-spec definer
    first2 method definer ;

M: method-spec definition
    first2 method definition ;

M: method-spec forget*
    first2 method forget* ;

M: method-spec smart-usage
    second smart-usage ;

M: method-body definer
    drop \ M: \ ; ;

M: method-body forget*
    dup "forgotten" word-prop [ drop ] [
        [
            dup "default" word-prop [ drop ] [
                [
                    [ "method-class" word-prop ]
                    [ "method-generic" word-prop ] bi
                    2dup method
                ] keep eq?
                [ [ delete-at ] with-methods ] [ 2drop ] if
            ] if
        ]
        [ call-next-method ] bi
    ] if ;

M: method-body smart-usage
    "method-generic" word-prop smart-usage ;

GENERIC: implementors ( class/classes -- seq )

M: class implementors
    all-words [ "methods" word-prop key? ] with filter ;

M: sequence implementors
    all-words [
         "methods" word-prop keys
        swap [ memq? ] curry contains?
    ] with filter ;

: forget-methods ( class -- )
    [ implementors ] [ [ swap 2array ] curry ] bi map forget-all ;

: forget-class ( class -- )
    class-usages [
        {
            [ forget-predicate ]
            [ forget-methods ]
            [ update-map- ]
            [ reset-class ]
        } cleave
    ] each ;

M: class forget* ( class -- )
    [ forget-class ] [ call-next-method ] bi ;

M: sequence update-methods ( class seq -- )
    implementors [
        [ update-generic ] [ make-generic drop ] 2bi
    ] with each ;

: define-generic ( word combination -- )
    over "combination" word-prop over = [
        2drop
    ] [
        2dup "combination" set-word-prop
        over H{ } clone "methods" set-word-prop
        dupd define-default-method
        make-generic
    ] if ;

M: generic subwords
    [
        [ "default-method" word-prop , ]
        [ "methods" word-prop values % ]
        [ "engines" word-prop % ]
        tri
    ] { } make ;

M: generic forget*
    [ subwords forget-all ] [ call-next-method ] bi ;

: xref-generics ( -- )
    all-words [ subwords [ xref ] each ] each ;
