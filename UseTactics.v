(** * UseTactics: Tactic Library for Coq: a gentle introduction *)

(* $Date: 2011-11-22 16:31:24 -0500 (Tue, 22 Nov 2011) $ *)
(* Chapter maintained by Arthur Chargueraud *)

(** Coq comes with a set of builtin tactics, such as [reflexivity],
    [intros], [inversion] and so on. While it is possible to conduct 
    proofs using only those tactics, you can significantly increase 
    your productivity by working with a set of more powerful tactics. 
    This chapter describes a number of such very useful tactics, which, 
    for various reasons, are not yet available by default in Coq.
    These tactics are defined in the [LibTactics.v] file. *)

Require Import LibTactics. 

(** Remark: SSReflect is another package providing powerful tactics.
    The library "LibTactics" differs from "SSReflect" in two respects:
        - "SSReflect" was primarily developed for proving mathematical
          theorems, whereas "LibTactics" was primarily developed for proving
          theorems on programming languages. In particular, "LibTactics" 
          provides a number of useful tactics that have no counterpart in the 
          "SSReflect" package.
        - "SSReflect" entirely rethinks the presentation of tactics,
          whereas "LibTactics" mostly stick to the traditional
          presentation of Coq tactics, simply providing a number of
          additional tactics.  For this reason, "LibTactics" is
          probably easier to get started with than "SSReflect". *)

(** This chapter is a tutorial focusing on the most useful features
    from the "LibTactics" library. It does not aim at presenting all
    the features of "LibTactics". The detailed specification of tactics
    can be found in the source file [LibTactics.v]. Further documentation 
    as well as demos can be found at http://www.chargueraud.org/softs/tlc/ . *)

(** In this tutorial, tactics are presented using examples taken from
    the core chapters of the "Software Foundations" course. To illustrate 
    the various ways in which a given tactic can be used, we use a 
    tactic that duplicates a given goal. More precisely, [dup] produces 
    two copies of the current goal, and [dup n] produces [n] copies of it. *)


(* ####################################################### *)
(** * Tactics for introduction and case analysis *)

(** This section presents the following tactics:
    - [introv], for naming hypotheses more efficiently,
    - [inverts], for improving the [inversion] tactic,
    - [cases], for performing a case analysis without losing information,
    - [cases_if], for automating case analysis on the argument of [if]. *)


(* ####################################################### *)
(** ** The tactic [introv] *)

Module IntrovExamples.
  Require Import Stlc.
  Import Imp STLC. 

(** The tactic [introv] allows to automatically introduce the 
    variables of a theorem and explicitly name the hypotheses 
    involved. In the example shown next, the variables [c], 
    [st], [st1] and [st2] involved in the statement of determinacy
    need not be named explicitly, because their name where already
    given in the statement of the lemma. On the contrary, it is
    useful to provide names for the two hypotheses, which we 
    name [E1] and [E2], respectively. *)

Theorem ceval_deterministic: forall c st st1 st2,
  c / st || st1 ->
  c / st || st2 ->
  st1 = st2.
Proof.
  introv E1 E2. (* was [intros c st st1 st2 E1 E2] *)
Admitted.

(** When there is no hypothesis to be named, one can call 
    [introv] without any argument. *)

Theorem ceval_and_ceval_step_coincide: forall c st st',
      c / st || st'
  <-> exists i, ceval_step st c i = Some st'.
Proof.
  introv. (* was [intros c st st'] *) 
Admitted.


(** The tactic [introv] also applies to statements in which
    [forall] and [->] are interleaved. *)
 
Theorem ceval_deterministic': forall c st st1,
  (c / st || st1) -> forall st2, (c / st || st2) -> st1 = st2.
Proof.
  introv E1 E2. (* was [intros c st st1 E1 st2 E2] *)
Admitted.

(** Like the arguments of [intros], the arguments of [introv] 
    can be structured patterns. *)

Theorem ceval_step__ceval: forall c st st',
      (exists i, ceval_step st c i = Some st') ->
      c / st || st'.
Proof.
  introv [i E].
  (* was [intros c st st' [i E].], which is itself short 
     for [intros c st st' H. destruct H as [i E].] *)
Admitted.

(** Remark: the tactic [introv] works even when definitions 
    need to be unfolded in order to reveal hypotheses. *)

End IntrovExamples.


(* ####################################################### *)
(** ** The tactic [inverts] *)

Module InvertsExamples.
  Require Import Stlc Equiv Imp.
  Import STLC.

(** The [inversion] tactic of Coq is not very satisfying for
    three reasons. First, it produces a bunch of equalities 
    which one typically wants to substitute away, using [subst].
    Second, it introduces meaningless names for hypotheses.
    Third, a call to [inversion H] does not remove [H] from the
    context, even though in most cases an hypothesis is no longer 
    needed after being inverted. The tactic [inverts] address all 
    of these three issues. It is intented to be used in place of
    the tactic [inversion]. *)

(** The following example illustrates how the tactic [inverts H] 
    behaves mostly like [inversion H] except that it performs 
    some substitutions in order to eliminate the trivial equalities
    that are being produced by [inversion]. *)

Theorem skip_left: forall c,
  cequiv (SKIP; c) c.
Proof. 
  introv. split; intros H. 
  dup. (* duplicate the goal for comparison *)
  (* was: *)
  inversion H. subst. inversion H2. subst. assumption.
  (* now: *)
  inverts H. inverts H2. assumption.
Admitted.

(** A slightly more interesting example appears next. *)

Theorem ceval_deterministic: forall c st st1 st2,
  c / st || st1  ->
  c / st || st2 ->
  st1 = st2.
Proof. 
  introv E1 E2. generalize dependent st2.
  (ceval_cases (induction E1) Case); intros st2 E2.
  admit. admit. (* skip some basic cases *)
  dup. (* duplicate the goal for comparison *)
  (* was: *) inversion E2. subst. admit.
  (* now: *) inverts E2. admit.
Admitted.

(** The tactic [inverts H as.] is like [inverts H] except that the 
    variables and hypotheses being produced are placed in the goal
    rather than in the context. This strategy allows naming those
    new variables and hypotheses explicitly, using either [intros] 
    or [introv]. *)

Theorem ceval_deterministic': forall c st st1 st2,
     c / st || st1  ->
     c / st || st2 ->
     st1 = st2.
Proof. 
  introv E1 E2. generalize dependent st2.
  (ceval_cases (induction E1) Case); intros st2 E2; 
    inverts E2 as.
  Case "E_Skip". reflexivity.
  Case "E_Ass". 
    (* Observe that the variable [n] is not automatically 
       substituted because, contrary to [inversion E2; subst],
       the tactic [inverts E2] does not substitute the equalities
       that exist before running the inversion. *)     
    (* new: *) subst n. 
    reflexivity.
  Case "E_Seq". 
    (* Here, the newly created variables can be introduced
       using intros, so they can be assigned meaningful names,
       for example [st3] instead of [st'0]. *)
    (* new: *) intros st3 Red1 Red2.
    assert (st' = st3) as EQ1.
      SCase "Proof of assertion". apply IHE1_1; assumption.
    subst st3.
    apply IHE1_2. assumption. 
  Case "E_IfTrue". 
    SCase "b1 evaluates to true".
      (* In an easy case like this one, there is no need to
         provide meaningful names, so we can just use [intros] *)
      (* new: *) intros. 
      apply IHE1. assumption.
    SCase "b1 evaluates to false (contradiction)".
      (* new: *) intros.
      rewrite H in H5. inversion H5.
  (* The other cases are similiar *)
Admitted.

(** In the particular case where a call to [inversion] produces 
    a single subgoal, one can use the syntax [inverts H as H1 H2 H3] 
    for calling [inverts] and naming the new hypotheses [H1], [H2] 
    and [H3]. In other words, the tactic [inverts H as H1 H2 H3] is
    equivalent to [invert H; introv H1 H2 H3]. An example follows. *)

Theorem skip_left': forall c,
  cequiv (SKIP; c) c.
Proof. 
  introv. split; intros H.
  inverts H as U V. (* new hypotheses are named [U] and [V] *)
  inverts U. assumption.
Admitted.

(** A more involved example appears next. In particular, this example
    shows that the name of the hypothesis being inverted can be reused. *)

Example typing_nonexample_1 :
  ~ exists T,
      has_type empty 
        (tm_abs a ty_Bool
            (tm_abs b ty_Bool
               (tm_app (tm_var a) (tm_var b))))
        T.
Proof.
  dup 3.

  (* The old proof: *)
  intros C. destruct C.
  inversion H. subst. clear H.
  inversion H5. subst. clear H5.
  inversion H4. subst. clear H4.
  inversion H2. subst. clear H2.
  inversion H5. subst. clear H5.
  inversion H1. 

  (* The new proof: *)
  intros C. destruct C.
  inverts H as H1.
  inverts H1 as H2.
  inverts H2 as H3.
  inverts H3 as H4.
  inverts H4.

  (* The new proof, alternative: *)
  intros C. destruct C.
  inverts H as H.
  inverts H as H.
  inverts H as H.
  inverts H as H.
  inverts H.
Qed.

End InvertsExamples.

(** Note: in the rare cases where one need to perform an inversion
    on an hypothesis [H] without clearing [H] from the context,
    one can use the tactic [inverts keep H], where the keyword [keep]
    indicates that the hypothesis should be kept in the context. *)


(* ####################################################### *)
(** ** The tactics [cases] and [cases_if] *)

Module CasesExample.
  Require Import Stlc.
  Import STLC.

(** As you probably have learned, the tactic [destruct] can be used
    to perform a case analysis. However, this tactic sometimes destroy
    useful information. The tactic [remember] is intended to introduce
    an equality that avoids [destruct] loosing such useful information.
    The tactic [cases] provided by [LibTactics] packages [remember]
    and [destruct] together in order to shorten proof scripts.

    The tactic [cases E] behaves like [remember E as x; destruct x],
    only with the difference that it generates the symmetric of the
    equality produced by [remember]. For example, [cases] would
    produce the equality [beq_id k1 k2 = true] rather than the
    equality [true = beq_id k1 k2]. Indeed, the former reads much more
    naturally than the latter. Moreover, the syntax [cases E as H] allows 
    to involve the [cases] tactic by specifying how to name the equality
    generated.
   
    Remark: [cases] is quite similar to [case_eq]. For the sake of 
    compatibility with [remember] and [case_eq], the library 
    "LibTactics" provides a tactic called [cases'] that generates exactly 
    the same equalities as [remember] or [case_eq] would, i.e., producing 
    an equality in the form [true = beq_id k1 k2] rather than 
    [beq_id k1 k2 = true]. The following examples illustrate the 
    behavior of the tactic [cases' E as H]. *)

Theorem update_same : forall x1 k1 k2 (f : state),
  f k1 = x1 ->
  (update f k1 x1) k2 = f k2.
Proof.
  intros x1 k1 k2 f Heq.
  unfold update. subst. 
  dup.
  
  (* The old proof: *)
  remember (beq_id k1 k2) as b. destruct b.
    apply beq_id_eq in Heqb. subst. reflexivity.
    reflexivity.  

  (* The new proof: *)
  cases' (beq_id k1 k2) as E.
    apply beq_id_eq in E. subst. reflexivity.
    reflexivity.  
Qed.

(** The tactic [cases_if] is a tactic that allows performing a case
    analysis without having to explicitly specify which value the
    case analysis should be upon. More precisely, the tactic [cases_if]
    looks in the goal or in the context for an expression of the form
    [if E then .. else ..], and it invokes [cases E]. Remark: if there 
    are several possibilities, [cases_if] only consider the first one.

    The tactic [cases_if] thus saves the need to copy-past an expression
    that occurs in the current proof obligation, leading to shorter and
    more robust proof scripts.

    Here again, for compatibility reasons, the library provides a tactic
    called [cases_if']. Moreover, one may write [cases_if as H] or 
    [cases_if' as H] for specifying the name to use for the generated
    equality. *)

Theorem update_same' : forall x1 k1 k2 (f : state),
  f k1 = x1 ->
  (update f k1 x1) k2 = f k2.
Proof.
  intros x1 k1 k2 f Heq.
  unfold update. subst. 
 
  (* The new proof: *)
  cases_if' as E.
    apply beq_id_eq in E. subst. reflexivity.
    reflexivity.  
Qed.

End CasesExample.



(* ####################################################### *)
(** * Tactics for n-ary connectives *)

(** Because Coq encodes conjunctions and disjunctions using binary 
    constructors [/\] and [\/], working with a conjunction or a
    disjunction of [N] facts can sometimes be quite cumbursome.
    For this reason, "LibTactics" provides tactics offering direct
    support for n-ary conjunctions and disjunctions. It also provides
    direct support for n-ary existententials. *)

(** This section presents the following tactics:
    - [splits] for decomposing n-ary conjunctions,
    - [branch] for decomposing n-ary disjunctions,
    - [exists] for proving n-ary existentials. *)
    
Module NaryExamples.
  Require Import References SfLib. 
  Import STLCRef.


(* ####################################################### *)
(** ** The tactic [splits] *)

(** The tactic [splits] applies to a goal made of a conjunction 
    of [n] propositions and it produces [n] subgoals. For example,
    it decomposes the goal [G1 /\ G2 /\ G3] into the three subgoals
    [G1], [G2] and [G3]. *)

Lemma demo_splits : forall n m,
  n > 0 /\ n < m /\ m < n+10 /\ m <> 3.
Proof.
  intros. splits.
Admitted.


(* ####################################################### *)
(** ** The tactic [branch] *)

(** The tactic [branch k] can be used to proved a n-ary disjunction.
    For example, if the goal takes the form [G1 \/ G2 \/ G3],
    the tactic [branch 2] leaves only [G2] as subgoal. The following
    example illustrates the behavior of the [branch] tactic. *)

Lemma demo_branch : forall n m,
  n < m \/ n = m \/ m < n.
Proof.
  intros.
  destruct (lt_eq_lt_dec n m) as [[H1|H2]|H3].
  branch 1. apply H1.
  branch 2. apply H2.
  branch 3. apply H3.
Qed.


(* ####################################################### *)
(** ** The tactic [exists] *)

(** The library "LibTactics" introduces a notation for n-ary
    existentials. For example, one can write [exists x y z, H]
    instead of [exists x, exists y, exists z, H]. Similarly,
    the library provides a n-ary tactic [exists a b c], which is a
    shorthand for [exists a; exists b; exists c]. The following
    example illustrates both the notation and the tactic for
    dealing with n-ary existentials. *)

Theorem progress : forall ST t T st,
  has_type empty ST t T ->
  store_well_typed ST st ->
  value t \/ exists t' st', t / st ==> t' / st'.
  (* was: [value t \/ exists t', exists st', t / st ==> t' / st'] *)
Proof with eauto.
  intros ST t T st Ht HST. remember (@empty ty) as Gamma.
  (has_type_cases (induction Ht) Case); subst; try solve by inversion...
  Case "T_App".
    right. destruct IHHt1 as [Ht1p | Ht1p]...
    SCase "t1 is a value".
      inversion Ht1p; subst; try solve by inversion.
      destruct IHHt2 as [Ht2p | Ht2p]...
      SSCase "t2 steps".
        inversion Ht2p as [t2' [st' Hstep]].
        exists (tm_app (tm_abs x T t) t2') st'...
        (* was: [exists (tm_app (tm_abs x T t) t2'). exists st'...] *)
Admitted.

(** Remark: a similar facility for n-ary existentials is provided
    by the module [Coq.Program.Syntax] from the standard library.
    ([Coq.Program.Syntax] supports existentials up to arity 4;
    [LibTactics] supports them up to arity 10. *)

End NaryExamples.


(* ####################################################### *)
(** * Tactics for working with equality *)

(** One of the major weakness of Coq compared with other interactive
    proof assistants is its relatively poor support for reasoning
    with equalities. The tactics described next aims at simplifying
    pieces of proof scripts manipulating equalities. *)

(** This section presents the following tactics:
    - [asserts_rewrite] for introducing an equality to rewrite with,
    - [cuts_rewrite], which is similar except that its subgoals are swapped,
    - [substs] for improving the [subst] tactic,
    - [fequals] for improving the [f_equal] tactic,
    - [applys_eq] for proving [P x y] using an hypothesis [P x z],
      automatically producing an equality [y = z] as subgoal. *)

Module EqualityExamples.


(* ####################################################### *)
(** ** The tactics [asserts_rewrite] and [cuts_rewrite] *)

(** The tactic [asserts_rewrite (E1 = E2)] replaces [E1] with [E2] in
    the goal, and produces the goal [E1 = E2]. *)

Theorem mult_0_plus : forall n m : nat,
  (0 + n) * m = n * m.
Proof.
  dup.
  (* The old proof: *)
  intros n m.
  assert (H: 0 + n = n). reflexivity. rewrite -> H. 
  reflexivity.
  
  (* The new proof: *)
  intros n m.
  asserts_rewrite (0 + n = n).
    reflexivity. (* subgoal [0+n = n] *)
    reflexivity. (* subgoal [n*m = m*n] *)
Qed.

(*** Remark: the syntax [asserts_rewrite (E1 = E2) in H] allows
     rewriting in the hypothesis [H] rather than in the goal. *)

(** The tactic [cuts_rewrite (E1 = E2)] is like
    [asserts_rewrite (E1 = E2)], except that the equality [E1 = E2]
    appears as first subgoal. *)

Theorem mult_0_plus' : forall n m : nat,
  (0 + n) * m = n * m.
Proof.
  intros n m.
  cuts_rewrite (0 + n = n).
    reflexivity. (* subgoal [n*m = m*n] *)
    reflexivity. (* subgoal [0+n = n] *)
Qed.

(** More generally, the tactics [asserts_rewrite] and [cuts_rewrite] 
    can be provided a lemma as argument. For example, one can write 
    [asserts_rewrite (forall a b, a*(S b) = a*b+a)]. 
    This formulation is useful when [a] and [b] are big terms,
    since there is no need to repeat their statements. *)

Theorem mult_0_plus'' : forall u v w x y z: nat,
  (u + v) * (S (w * x + y)) = z.
Proof.
  intros. asserts_rewrite (forall a b, a*(S b) = a*b+a).
    (* first subgoal:  [forall a b, a*(S b) = a*b+a] *)
    (* second subgoal: [(u + v) * (w * x + y) + (u + v) = z] *)
Admitted.


(* ####################################################### *)
(** ** The tactic [substs] *)

(** The tactic [substs] is similar to [subst] except that it
    does not fail when the goal contains "circular equalities",
    such as [x = f x]. *)

Lemma demo_substs : forall x y (f:nat->nat), 
  x = f x -> y = x -> y = f x.
Proof.
  intros. substs. (* the tactic [subst] would fail here *) 
  assumption.
Qed.


(* ####################################################### *)
(** ** The tactic [fequals] *)

(** The tactic [fequals] is similar to [f_equal] except that it 
    directly discharges all the trivial subgoals produced. Moreover, 
    the tactic [fequals] features an enhanced treatment of equalities
    between tuples. *)

Lemma demo_fequals : forall (a b c d e : nat) (f : nat->nat->nat->nat->nat),
  a = 1 -> b = e -> e = 2 -> 
  f a b c d = f 1 2 c 4.
Proof.
  intros. fequals. 
  (* subgoals [a = 1], [b = 2] and [c = c] are proved, [d = 4] remains *)
Admitted.


(* ####################################################### *)
(** ** The tactic [applys_eq] *)

(** The tactic [applys_eq] is a variant of [eapply] that introduces
    equalities for subterms that do not unify. For example, assume
    the goal is the proposition [P x y] and assume we have the
    assumption [H] asserting that [P x z] holds. We know that we can 
    prove [y] to be equal to [z]. So, we could call the tactic
    [assert_rewrite (y = z)] and change the goal to [P x z], but
    this would require copy-pasting the values of [y] and [z].
    With the tactic [applys_eq], we can call [applys_eq H 1], which
    proves the goal and leaves only the subgoal [y = z]. The value [1]
    given as argument to [applys_eq] indicates that we want an equality
    to be introduced for the first argument of [P x y] counting from
    the right. The three following examples illustrate the behavior
    of a call to [applys_eq H 1], a call to [applys_eq H 2], and a
    call to [applys_eq H 1 2]. *)

Axiom big_expression_using : nat->nat. (* Used in the example *)
  
Lemma demo_applys_eq_1 : forall (P:nat->nat->Prop) x y z, 
  P x (big_expression_using z) -> 
  P x (big_expression_using y).
Proof.
  introv H. dup.

  (* The old proof: *)
  assert (Eq: big_expression_using y = big_expression_using z).
    admit. (* Assume we can prove this equality somehow. *)
  rewrite Eq. apply H.

  (* The new proof: *)
  applys_eq H 1.
    admit. (* Assume we can prove this equality somehow. *)
Qed.

(** If the mismatch was on the first argument of [P] instead of
    the second, we would have written [applys_eq H 2]. Recall
    that the occurences are counted from the right. *)

Lemma demo_applys_eq_2 : forall (P:nat->nat->Prop) x y z, 
  P (big_expression_using z) x -> 
  P (big_expression_using y) x.
Proof.
  introv H. applys_eq H 2.
Admitted.

(** When we have a mismatch on two arguments, we want to produce
    two equalities. To achieve this, we may call [applys_eq H 1 2].
    More generally, the tactic [applys_eq] expects a lemma and a
    sequence of natural numbers as arguments. *)

Lemma demo_applys_eq_3 : forall (P:nat->nat->Prop) x1 x2 y1 y2, 
  P (big_expression_using x2) (big_expression_using y2) -> 
  P (big_expression_using x1) (big_expression_using y1).
Proof.
  introv H. applys_eq H 1 2.
  (* produces two subgoals:
     [big_expression_using x1 = big_expression_using x2]
     [big_expression_using y1 = big_expression_using y2] *)
Admitted.

End EqualityExamples.


(* ####################################################### *)
(** * Some convenient shorthands *)

(** This section of the tutorial introduces a few tactics 
    that help make proof scripts shorter and more readable:
    - [unfolds] (without argument) for unfolding the head definition,
    - [false] for replacing the goal with [False],
    - [gen] as a shorthand for [dependent generalize],
    - [skip] for skipping a subgoal even if it contains existential variables,
    - [sort] for re-ordering the proof context by moving moving all
      propositions at the bottom. *)


(* ####################################################### *)
(** ** The tactic [unfolds] *)

Module UnfoldsExample.
  Require Import Hoare.

(** The tactic [unfolds] (without any argument) unfolds the
    head constant of the goal. This tactic saves the need to 
    name the constant explicitly. *)

Lemma bexp_eval_true : forall b st,
  beval st b = true -> (bassn b) st.
Proof.
  intros b st Hbe. dup.

  (* The old proof: *)
  unfold bassn. assumption.

  (* The new proof: *)
  unfolds. assumption. 
Qed.

(** Remark: contrary to the tactic [hnf], which may unfold several
    constants, [unfolds] performs only a single step of unfolding. *)

(** Remark: the tactic [unfolds in H] can be used to unfold the 
    head definition of the hypothesis [H]. *)

End UnfoldsExample.


(* ####################################################### *)
(** ** The tactics [false] and [tryfalse] *)

(** The tactic [false] can be used to replace any goal with [False].
    In short, it is a shorthand for [apply ex_falso_quodlibet]. 
    Moreover, [false] proves the goal if it contains an absurd 
    assumption, such as [False] or [0 = S n], or if it contains
    contradictory assumptions, such as [x = true] and [x = false]. *)

Lemma demo_false : 
  forall n, S n = 1 -> n = 0.
Proof.
  intros. destruct n. reflexivity. false.
Qed.

(** The tactic [false] can be given an argument: [false H] replace
    the goals with [False] and then applies [H]. *)

Lemma demo_false_arg : 
  (forall n, n < 0 -> False) -> (3 < 0) -> 4 < 0.
Proof.
  intros H L. false H. apply L.
Qed.

(** The tactic [tryfalse] is a shorthand for [try solve [false]]:
    it tries to find a contradiction in the goal. The tactic
    [tryfalse] is generally called after a case analysis. *)

Lemma demo_tryfalse : 
  forall n, S n = 1 -> n = 0.
Proof.
  intros. destruct n; tryfalse. reflexivity.
Qed.


(* ####################################################### *)
(** ** The tactic [gen] *)

(** The tactic [gen] is a shortand for [generalize dependent]
    that accepts several arguments at once. An invokation of 
    this tactic takes the form [gen x y z]. *)

Module GenExample.
  Require Import Stlc.
  Import STLC.

Lemma substitution_preserves_typing : forall Gamma x U v t S,
     has_type (extend Gamma x U) t S ->
     has_type empty v U ->
     has_type Gamma (subst v x t) S.
Proof.
  dup.

  (* The old proof: *)
  intros Gamma x U v t S Htypt Htypv.
  generalize dependent S. generalize dependent Gamma.
  induction t; intros; simpl.
  admit. admit. admit. admit. admit. admit.

  (* The new proof: *)
  introv Htypt Htypv. gen S Gamma. 
  induction t; intros; simpl.
  admit. admit. admit. admit. admit. admit.
Qed.

End GenExample.


(* ####################################################### *)
(** ** The tactics [skip], [skip_rewrite] and [skip_goal] *)

(** Temporarily admitting a given subgoal is very useful when
    constructing proofs. It gives the ability to focus first 
    on the most interesting cases of a proof. The tactic [skip]
    is like [admit] except that it also works when the proof 
    includes existential variables. Recall that existential 
    variables are those whose name starts with a question mark, 
    e.g. [?24], and which are typically introduced by [eapply]. *)

Module SkipExample.
  Require Import Stlc.
  Import STLC.

Example astep_example1 : 
  (APlus (ANum 3) (AMult (ANum 3) (ANum 4))) / empty_state ==>a* (ANum 15).
Proof.
  eapply rsc_step. skip. (* the tactic [admit] would not work here *)
  eapply rsc_step. skip. skip.
  (* Note that because some unification variables have
     not been instantiated, we still need to write
     [Admitted] instead of [Qed] at the end of the proof. *)
Admitted.

(** The tactic [skip H: P] adds the hypothesis [H: P] to the context, 
    without checking whether the proposition [P] is true. 
    It is useful for exploiting a fact and postponing its proof. 
    Note: [skip H: P] is simply a shorthand for [assert (H:P). skip.] *)

Theorem demo_skipH : True.
Proof.
  skip H: (forall n m : nat, (0 + n) * m = n * m).
Admitted.

(** The tactic [skip_rewrite (E1 = E2)] replaces [E1] with [E2] in
    the goal, without checking that [E1] is actually equal to [E2]. *)

Theorem mult_0_plus : forall n m : nat,
  (0 + n) * m = n * m.
Proof.
  dup.

  (* The old proof: *)
  intros n m.
  assert (H: 0 + n = n). skip. rewrite -> H. 
  reflexivity.

  (* The new proof: *)
  intros n m.
  skip_rewrite (0 + n = n).
  reflexivity.
Qed.

(** Remark: the tactic [skip_rewrite] can in fact be given a lemma
    statement as argument, in the same way as [asserts_rewrite]. *)

(** The tactic [skip_goal] adds the current goal as hypothesis.
    This cheat is useful to set up the structure of a proof by
    induction without having to worry about the induction hypothesis 
    being applied only to smaller arguments. Using [skip_goal], one
    can construct a proof in two steps: first, check that the main
    arguments go through without waisting time on fixing the details
    of the induction hypotheses; then, focus on fixing the invokations
    of the induction hypothesis. *)

Theorem ceval_deterministic: forall c st st1 st2,
  c / st || st1 ->
  c / st || st2 ->
  st1 = st2.
Proof.  
  (* The tactic [skip_goal] creates an hypothesis called [IH] 
     asserting that the statment of [ceval_deterministic] is true. *)
  skip_goal.
  (* Of course, if we call [assumption] here, then the goal is solved
     right away, but the point is to do the proof and use [IH]
     only at the places where we need an induction hypothesis. *)
  introv E1 E2. gen st2.
  (ceval_cases (induction E1) Case); introv E2; inverts E2 as.
  Case "E_Skip". reflexivity.
  Case "E_Ass". 
    subst n. 
    reflexivity.
  Case "E_Seq". 
    intros st3 Red1 Red2.
    assert (st' = st3) as EQ1.
      SCase "Proof of assertion". 
        (* was: [apply IHE1_1; assumption.] *)
        (* new: *) eapply IH. eapply E1_1. eapply Red1.
    subst st3.
    (* was: apply IHE1_2. assumption.] *)
    (* new: *) eapply IH. eapply E1_2. eapply Red2.
  (* The other cases are similiar. *)
Admitted.

End SkipExample.


(* ####################################################### *)
(** ** The tactic [sort] *)

Module SortExamples.
  Require Import Imp.

(** The tactic [sort] reorganizes the proof context by placing
    all the variables at the top and all the hypotheses at the
    bottom, thereby making the proof context more readable. *)

Theorem ceval_deterministic: forall c st st1 st2,
  c / st || st1 ->
  c / st || st2 ->
  st1 = st2.
Proof. 
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  (ceval_cases (induction E1) Case); intros st2 E2; inverts E2.
  admit. admit. (* Skipping some trivial cases *)
  sort. (* Observe how the context is reorganized *)
Admitted.

End SortExamples.


(* ####################################################### *)
(** * Tactics for advanced lemma instantiation *)

(** This last section describes a mechanism for instantiating a lemma 
    by providing some of its arguments and leaving other implicit. 
    Variables whose instantiation is not provided are turned into 
    existentential variables, and facts whose instantiation is not 
    provided are turned into subgoals. 
    
    Remark: this instantion mechanism goes far beyond the abilities of 
    the "Implicit Arguments" mechanism. The point of the instantiation 
    mechanism described in this section is that you will no longer need 
    to spend time figuring out how many underscore symbols you need to 
    write. *)

(** In this section, we'll use a useful feature of Coq for decomposing
    conjunctions and existentials. In short, a tactic like [intros] or
    [destruct] can be provided with a pattern [(H1 & H2 & H3 & H4 & H5)],
    which is a shorthand for [[H1 [H2 [H3 [H4 H5]]]]]]. For example,
    [destruct (H _ _ _ Htypt) as [T [Hctx Hsub]].] can be rewritten in
    the form [destruct (H _ _ _ Htypt) as (T & Hctx & Hsub).] *)


(* ####################################################### *)
(** ** Working of [lets] *)

(** When we have a lemma (or an assumption) that we want to exploit,
    we often need to explicitly provide arguments to this lemma,
    writing something like:
    [destruct (typing_inversion_var _ _ _ Htypt) as (T & Hctx & Hsub).]
    The need to write several times the "underscore" symbol is tedious.
    Not only we need to figure out how many of them to write down, but
    it also makes the proof scripts look prettly ugly. With the tactic
    [lets], one can simply write:
    [lets (T & Hctx & Hsub): typing_inversion_var Htypt.]
   
    In short, this tactic [lets] allows to specialize a lemma on a bunch 
    of variables and hypotheses. The syntax is [lets I: E0 E1 .. EN], 
    for building an hypothesis named [I] by applying the fact [E0] to the 
    arguments [E1] to [EN]. Not all the arguments need to be provided,
    however the arguments that are provided need to be provided in the
    correct order. The tactic relies on a first-match algorithm based on 
    types in order to figure out how the to instantiate the lemma with
    the arguments provided. *)

Module ExamplesLets.
  Require Import Subtyping.

(* To illustrate the working of [lets], assume that we want to
   exploit the following lemma. *)

Axiom typing_inversion_var : forall (G:context) (x:id) (T:ty),
  has_type G (tm_var x) T ->
  exists S, G x = Some S /\ subtype S T.

(** First, assume we have an assumption [H] with the type of the form
    [has_type G (tm_var x) T]. We can obtain the conclusion of the
    lemma [typing_inversion_var] by invoking the tactics 
    [lets K: typing_inversion_var H], as shown next. *)

Lemma demo_lets_1 : forall (G:context) (x:id) (T:ty), 
  has_type G (tm_var x) T -> True.
Proof.
  intros G x T H. dup. 

  (* step-by-step: *)
  lets K: typing_inversion_var H.
  destruct K as (S & Eq & Sub). 
  admit.

  (* all-at-once: *)
  lets (S & Eq & Sub): typing_inversion_var H.
  admit.

Qed.

(** Assume now that we know the values of [G], [x] and [T] and we
    want to obtain [S], and have [has_type G (tm_var x) T] be produced
    as a subgoal. To indicate that we want all the remaining arguments
    of [typing_inversion_var] to be produced as subgoals, we use a
    triple-underscore symbol [___]. (We'll later introduce a shorthand
    tactic called [forwards] to avoid writing triple underscores.) *)

Lemma demo_lets_2 : forall (G:context) (x:id) (T:ty), True.
Proof.
  intros G x T. 
  lets (S & Eq & Sub): typing_inversion_var G x T ___.
Admitted.

(** Usually, there is only one context [G] and one type [T] that are
    going to be suitable for proving [has_type G (tm_var x) T], so
    we don't really need to bother giving [G] and [T] explicitly.
    It suffices to call [lets (S & Eq & Sub): typing_inversion_var x].
    The variables [G] and [T] are then instantiated using existential 
    variables. *)

Lemma demo_lets_3 : forall (x:id), True.
Proof.
  intros x. 
  lets (S & Eq & Sub): typing_inversion_var x ___.
Admitted.

(** We may go even further by not giving any argument to instantiate
    [typing_inversion_var]. In this case, three unification variables
    are introduced. *)

Lemma demo_lets_4 : True.
Proof.
  lets (S & Eq & Sub): typing_inversion_var ___.
Admitted.

(** Note: if we provide [lets] with only the name of the lemma as 
    argument, it simply adds this lemma in the proof context, without 
    trying to instantiate any of its arguments. *)

Lemma demo_lets_5 : True.
Proof.
  lets H: typing_inversion_var.
Admitted.

(** A last useful feature of [lets] is the double-underscore symbol,
    which allows skipping an argument when several arguments have
    the same type. In the following example, our assumption quantifies
    over two variables [n] and [m], both of type [nat]. We would like
    [m] to be instantiated as the value [3], but without specifying a
    value for [n]. This can be achieved by writting [lets K: H __ 3]. *)

Lemma demo_lets_underscore : 
  (forall n m, n <= m -> n < m+1) -> True.
Proof.
  intros H.

  (* If we do not use a double underscore, the first argument,
     which is [n], gets instantiated as 3. *)
  lets K: H 3. (* gives [K] of type [forall m, 3 <= m -> 3 < m+1] *)
    clear K.

  (* The double underscore preceeding [3] indicates that we want 
     to skip a value that has the type [nat] (because [3] has 
     the type [nat]). So, the variable [m] gets instiated as [3]. *)
  lets K: H __ 3. (* gives [K] of type [?X <= 3 -> ?X < 3+1] *)
    clear K.
Admitted.


(** Note: one can write [lets: E0 E1 E2] in place of [lets H: E0 E1 E2].
    In this case, the name [H] is chosen arbitrarily.

    Note: the tactics [lets] accepts up to five arguments. Another
    syntax if available for providing more than five arguments.
    It consists in using a list introduced with the special symbol [>>],
    for example [lets H: (>> E0 E1 E2 E3 E4 E5 E6 E7 E8 E9 10)]. *)

End ExamplesLets.


(* ####################################################### *)
(** ** Working of [applys], [forwards] and [specializes] *)

(** The tactics [applys], [forwards] and [specializes] are 
    shorthand that may be used in place of [lets] to perform
    specific tasks.

    - [forwards] is a shorthand for instantiating all the arguments
    of a lemma. More precisely, [forwards H: E0 E1 E2 E3] is the 
    same as [lets H: E0 E1 E2 E3 ___], where the triple-underscore 
    has the same meaning as explained earlier on. 

    - [applys] allows building a lemma using the advanced instantion
    mode of [lets], and then apply that lemma right away. So,
    [applys E0 E1 E2 E3] is the same as [lets H: E0 E1 E2 E3]
    followed with [eapply H] and then [clear H]. 
    
    - [specializes] is a shorthand for instantiating in-place 
    an assumption from the context with particular arguments.
    More precisely, [specializes H E0 E1] is the same as 
    [lets H': H E0 E1] followed with [clear H] and [rename H' into H].

    Examples of use of [applys] appear further on. Several examples 
    of use of [specializes] and [forwards] can be found in the 
    tutorial file [UseAuto.v]. *)


(* ####################################################### *)
(** ** Example of instantiations *)

Module ExamplesInstantiations.
  Require Import Subtyping.

(** The following proof shows several examples where [lets] is used
    instead of [destruct], as well as examples where [applys] is used
    instead of [apply]. The proof also contains some holes that you
    need to fill in as an exercise. *)

Lemma substitution_preserves_typing : forall Gamma x U v t S,
     has_type (extend Gamma x U) t S ->
     has_type empty v U ->
     has_type Gamma (subst v x t) S.
Proof with eauto.
  intros Gamma x U v t S Htypt Htypv.
  generalize dependent S. generalize dependent Gamma.
  (tm_cases (induction t) Case); intros; simpl.
  Case "tm_var".
    rename i into y.

    (* An example where [destruct] is replaced with [lets]. *)
    (* old: destruct (typing_inversion_var _ _ _ Htypt) as [T [Hctx Hsub]].*)
    (* new: *) lets (T&Hctx&Hsub): typing_inversion_var Htypt.
    unfold extend in Hctx.
    remember (beq_id x y) as e. destruct e... 
    (* Note: [cases_if'] could be used to simplify the line above *)
    SCase "x=y".
      apply beq_id_eq in Heqe. subst.
      inversion Hctx; subst. clear Hctx.
      apply context_invariance with empty...
      intros x Hcontra.

       (* A more involved example. *)
       (* old: destruct (free_in_context _ _ S empty Hcontra) 
                 as [T' HT']... *)
       (* new: *)
        lets [T' HT']: free_in_context S empty Hcontra...
        inversion HT'.
  Case "tm_app".
    
    (* Exercise: replace the following [destruct] with a [lets]. *)
    (* old: destruct (typing_inversion_app _ _ _ _ Htypt) 
              as [T1 [Htypt1 Htypt2]]. eapply T_App... *)
    (* FILL IN HERE *) admit.
    
  Case "tm_abs".
    rename i into y. rename t into T1.

    (* Here is another example of using [lets]. *)
    (* old: destruct (typing_inversion_abs _ _ _ _ _ Htypt). *)
    (* new: *) lets (T2&Hsub&Htypt2): typing_inversion_abs Htypt.

    (* An example of where [apply with] can be replaced with [applys]. *)
    (* old: apply T_Sub with (ty_arrow T1 T2)... *)
    (* new: *) applys T_Sub (ty_arrow T1 T2)...
     apply T_Abs...
    remember (beq_id x y) as e. destruct e. 
    SCase "x=y".
      eapply context_invariance...
      apply beq_id_eq in Heqe. subst.
      intros x Hafi. unfold extend.
      destruct (beq_id y x)...
    SCase "x<>y".
      apply IHt. eapply context_invariance...
      intros z Hafi. unfold extend.
      remember (beq_id y z) as e0. destruct e0...
      apply beq_id_eq in Heqe0. subst.
      rewrite <- Heqe...
  Case "tm_true".
    lets: typing_inversion_true Htypt...
  Case "tm_false".
    lets: typing_inversion_false Htypt...
  Case "tm_if".
    lets (Htyp1&Htyp2&Htyp3): typing_inversion_if Htypt...
  Case "tm_unit". 
    (* An example where [assert] can be replaced with [lets]. *)
    (* old: assert (subtype ty_Unit S) 
             by apply (typing_inversion_unit _ _ Htypt)... *)
    (* new: *) lets: typing_inversion_unit Htypt...

  
Qed.

End ExamplesInstantiations.


(* ####################################################### *)
(** * Summary *)

(** In this chapter we have presented a number of tactics that help make
    proof script more concise and more robust on change. 
 
    - [introv] and [inverts] improve naming and inversions.

    - [false] and [tryfalse] help discarding absurd goals.
 
    - [unfolds] automatically calls [unfold] on the head definition.

    - [gen] helps setting up goals for induction.

    - [cases] and [cases_if] help with case analysis.
  
    - [splits], [branch] and [exists] to deal with n-ary constructs.

    - [asserts_rewrite], [cuts_rewrite], [substs] and [fequals] help
      working with equalities.
  
    - [lets], [forwards], [specializes] and [applys] provide means
      of very conveniently instantiating lemmas.
      
    - [applys_eq] can save the need to perform manual rewriting steps
      before being able to apply lemma.
    
    - [skip], [skip_rewrite] and [skip_goal] give the flexibility to
      choose which subgoals to try and discharge first.

    Making use of these tactics can boost one's productivity in Coq proofs.

    If you are interested in using [LibTactics.v] in your own developments, 
    make sure you get the lastest version from:
    http://www.chargueraud.org/softs/tlc/ .

*)
