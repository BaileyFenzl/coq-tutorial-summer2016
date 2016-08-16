Set Implicit Arguments.

Require Import pair_UOT.
Require Import ZArith List Bool.
Require Import MSets MSetFacts.

Module Type Graph (Node : UsualOrderedType).

  (* We want a way to talk about edges *)
  Module NodePair := PairUsualOrderedType Node Node.

  (* Build necessary modules *)
  Module mset := MSetAVL.Make Node.
  Module msetPair := MSetAVL.Make NodePair.
  Module mset_facts := WFacts (mset).
  Module msetPair_facts := WFacts (msetPair).
  Module mset_prop := WProperties (mset).
  Module msetPair_prop := WProperties (msetPair).

  (* Provide definitions for containers wrt to above modules *)
  Definition node := Node.t.
  Definition nodePair := NodePair.t.

  Definition node_set := mset.t.
  Definition node_setPair := msetPair.t.

  (* Some notation for commonly used predicates *)
  Notation In_ns := mset.In.
  Notation In_nsp := msetPair.In.

  (* The type of graphs *)
  Parameter t : Type.

  (* An empty graph *)
  Parameter empty : t.

  (* Functions for the addition/removal of edges and vertices *)
  Parameter add_vertex : t -> node -> t.
  Parameter add_edge : t -> (node*node) -> t.
  Parameter remove_vertex : t -> node -> t.
  Parameter remove_edge : t -> (node*node) -> t.

  (* Functions for finding edges/vertices of a graph *)
  Parameter vertices : t -> node_set.
  Parameter edges : t -> node_setPair.

  Parameter is_vertex : t -> node -> bool.
  Parameter is_edge : t -> (node*node) -> bool.
  
  Parameter neighborhood : t -> node -> node_set.

  (** empty *)
  Axiom empty_vertices : vertices empty = mset.empty.
  Axiom empty_edges : edges empty = msetPair.empty.  

  (** add *)
  Axiom add_vertices :
    forall (x : node) g,
      In_ns x (vertices (add_vertex g x)).
  Axiom add_edges :
    forall (e : node*node) g,
      In_ns (fst e) (vertices g) ->
      In_ns (snd e) (vertices g)->       
      In_nsp e (edges (add_edge g e)).
  Axiom add_vertices_other :
    forall (x y : node) g,
      x <> y -> In_ns y (vertices g) <-> In_ns y (vertices (add_vertex g x)).
  Axiom add_edges_other :
    forall (e1 e2 : node*node) g,
      e1 <> e2 -> In_nsp e2 (edges g) <-> In_nsp e2 (edges (add_edge g e1)).
  Axiom add_vertices_pres_edges :
    forall x g,
      edges (add_vertex g x) = (edges g).
  Axiom add_edges_pres_vertices :
    forall x g,
      vertices (add_edge g x) = (vertices g).

  (** remove *)
  Axiom remove_vertices :
    forall (x : node) g,
      ~In_ns x (vertices (remove_vertex g x)).
  Axiom remove_edges :
    forall (e : node*node) g,
      ~In_nsp e (edges (remove_edge g e)).
  (* Removal of vertices, ensures that the edge list remains valid *)
  Axiom remove_vertices_edges_l :
    forall (x1 : node) g,
      forall (x2 : node), ~ In_nsp (x1,x2) (edges (remove_vertex g x1)).
  Axiom remove_vertices_edges_r :
    forall (x1 : node) g,
      forall (x2 : node), ~ In_nsp (x2,x1) (edges (remove_vertex g x1)).
  Axiom remove_vertices_other :
    forall (x y : node) g,
      x <> y -> In_ns y (vertices g) <-> In_ns y (vertices (remove_vertex g x)).
  Axiom remove_edges_other :
    forall (e1 e2 : node*node) g,
      e1 <> e2 -> In_nsp e2 (edges g) <-> In_nsp e2 (edges (remove_edge g e1)).

  (** other properties *)
  Axiom is_vertex_vertices :
    forall x g,
      In_ns x (vertices g) <-> is_vertex g x = true.
  Axiom is_edge_edges :
    forall e g,
      In_nsp e (edges g) <-> is_edge g e = true.
  Axiom neighborhood_prop :
    forall x y g,
      In_ns y (neighborhood g x) <-> In_nsp (x,y) (edges g).
  Axiom edges_proper_l :
    forall x g,
      In_nsp x (edges g) -> In_ns (fst x) (vertices g).
  Axiom edges_proper_r :
    forall x g,
      In_nsp x (edges g) -> In_ns (snd x) (vertices g).

  (** Above are all of the REQUIRED elements for the module
      The following consist of definitions and derived facts **)

  Lemma edges_proper :
    forall x g,
      In_nsp x (edges g) ->
        In_ns (fst x) (vertices g) /\ In_ns (snd x) (vertices g).
  Proof.
    intros.
    split;
    [apply edges_proper_l | apply edges_proper_r];
    auto.
  Qed.

  (** In this section we define a setoid equality over our sets,
      establish that add_vertex and add_edge are morphisms
      and some facts regarding transpositions of add_vertex and
      add_edge.

      To do:
        Prove the same facts wrt. remove_vertex/remove_edge. **)

    Definition Equal (g1 g2 : t) :=
      mset.Equal (vertices g1) (vertices g2) /\
      msetPair.Equal (edges g1) (edges g2).
    Definition equal (g1 g2 : t) :=
      (mset.equal (vertices g1) (vertices g2)) &&
      (msetPair.equal (edges g1) (edges g2)).
    Lemma Equal_refl : Reflexive Equal.
    Proof.
    Admitted.
    Lemma Equal_symm : Symmetric Equal.
    Proof.
    Admitted.
    Lemma Equal_trans : Transitive Equal.
    Proof.
    Admitted.
    Lemma Equal_equiv : Equivalence Equal.
    Proof. 
      split; [exact Equal_refl | exact Equal_symm | exact Equal_trans].
    Qed.

    Theorem Equal_setoid : Setoid_Theory _ Equal.
      split; [exact Equal_refl | exact Equal_symm | exact Equal_trans].
    Qed.

  Lemma gen_Equal_V :
    forall g g', Equal g g' -> mset.Equal (vertices g) (vertices g').
  Proof. intros. apply H. Qed.

  Lemma gen_Equal_E :
    forall g g', Equal g g' -> msetPair.Equal (edges g) (edges g').
  Proof. intros. apply H. Qed.

    Add Parametric Relation : t Equal
      reflexivity proved by Equal_refl
      symmetry proved by Equal_symm
      transitivity proved by Equal_trans as graph_eq.

    Add Parametric Morphism : add_vertex with
      signature Equal ==> @eq node ==> Equal as add_vertex_morph.
    Proof.
      intros. split.
      {
      split; intros;
      destruct (Node.eq_dec a y0); subst.
      apply add_vertices.
      apply add_vertices_other; try congruence.
      apply add_vertices_other in H0; try congruence.
      apply H; auto.
      apply add_vertices.
      apply add_vertices_other; try congruence.
      apply add_vertices_other in H0; try congruence.
      apply H; auto.
      }
      {
        transitivity (edges x);
        rewrite add_vertices_pres_edges;
        [|apply H]; reflexivity.
      }
    Qed.

    Add Parametric Morphism : add_edge with
      signature Equal ==> @eq nodePair ==> Equal as add_edge_morph.
    Proof.
    intros. split.
    {
      transitivity (vertices x);
      rewrite add_edges_pres_vertices;
      [|apply H]; reflexivity.
    }
    {
      split; intros;
      destruct (NodePair.eq_dec a y0); subst;
      try solve
        [ apply edges_proper in H0;
          rewrite add_edges_pres_vertices in H0;
          destruct H0;apply add_edges; apply H; auto
        | apply add_edges_other; try congruence;
          apply add_edges_other in H0; try congruence;
          apply H; auto].
    }
    Qed.

  Lemma add_edges_transpose :
    forall x y g, Equal (add_edge (add_edge g y) x) (add_edge (add_edge g x) y).
  Proof.
    intros. split.
    {
      repeat rewrite add_edges_pres_vertices. reflexivity.
    }
    {
      split; intros;
      destruct (NodePair.eq_dec a x);
      destruct (NodePair.eq_dec a y); repeat subst; auto.
      apply edges_proper in H; repeat rewrite add_edges_pres_vertices in H.
      destruct H.
      {
        apply add_edges_other; try congruence; apply add_edges; auto.
      }
      {
        apply add_edges; apply edges_proper in H;
        repeat rewrite add_edges_pres_vertices in *;
        destruct H; auto.
      }
      {
        repeat apply add_edges_other; try congruence;
        repeat (apply add_edges_other in H; try congruence).
      }
      {
        apply add_edges; apply edges_proper in H;
        repeat rewrite add_edges_pres_vertices in *;
        destruct H; auto.
      }
      {
        apply add_edges_other; try congruence; apply add_edges;
        apply edges_proper in H;
        repeat rewrite add_edges_pres_vertices in H;  destruct H; auto.
      }
      {
        repeat apply add_edges_other; try congruence;
        repeat (apply add_edges_other in H; try congruence).
      }
    }
  Qed.

  Lemma add_vertices_transpose :
    forall x y g, Equal (add_vertex (add_vertex g y) x)
                        (add_vertex (add_vertex g x) y).
  Proof.
    intros. split.
    {
      split; intros;
      destruct (Node.eq_dec a x);
      destruct (Node.eq_dec a y); repeat subst; auto;
      try solve
        [ apply add_vertices_other; try congruence;
          apply add_vertices
        | apply add_vertices
        | repeat (apply add_vertices_other in H; try congruence);
          repeat (apply add_vertices_other; try congruence)].
    }
    repeat rewrite add_vertices_pres_edges. reflexivity.
  Qed.

  Definition const_vertices (v : node_set) : t :=
    mset.fold (fun elt subg => add_vertex subg elt) v empty.

  Definition const_edges (v : node_setPair) (g : t) :=
    msetPair.fold (fun elt subg => add_edge subg elt) v g.
  
  Definition rebuild_graph : t -> t :=
    fun g => const_edges (edges g) (const_vertices (vertices g)).

  (** Proofs that these functions result in equivalent graphs **)
  Lemma const_vertices_preservation g :
    mset.Equal (vertices g) (vertices (const_vertices (vertices g))).
  Proof.
    unfold const_vertices.
    apply mset_prop.fold_rec;
    intros.
    {
      apply mset_prop.empty_is_empty_1 in H.
      apply (mset_prop.equal_trans H).
      rewrite empty_vertices.
      apply mset_prop.equal_refl.
    }
    {
      apply mset_prop.Add_Equal in H1.
      apply (mset_prop.equal_trans H1).
      split; case (Node.eq_dec x a0); intros.
      {
        subst. apply add_vertices.
      }
      {
        apply add_vertices_other; auto.
        apply H2; auto.
        apply mset_prop.Dec.F.add_neq_iff in H3; auto.
      }
      {
        subst. apply mset_prop.Dec.F.add_1; auto.
      }
      {
        apply mset_prop.Dec.F.add_2.
        apply H2.
        apply add_vertices_other in H3; auto.
      }
    }
  Qed.

  Lemma const_vertices_empty_edges g :
    msetPair.Equal (edges (const_vertices (vertices g))) (msetPair.empty).
  Proof.
    unfold const_vertices.
    apply mset_prop.fold_rec.
    {
      intros. rewrite empty_edges.
      apply msetPair_prop.equal_refl.
    }
    {
      intros.
      rewrite add_vertices_pres_edges.
      auto.
    }
  Qed.

  Lemma const_edges_empty_vertices :
    forall v g, mset.Equal (vertices (const_edges v g)) (vertices g).
  Proof.
    intros.
    unfold rebuild_graph, const_edges.
    apply msetPair_prop.fold_rec.
    {
      intros. reflexivity.
    }
    {
      intros. rewrite add_edges_pres_vertices; auto.
    }
  Qed.

  Lemma const_edges_eq :
    forall v v' g, msetPair.Equal v v' ->
      Equal (const_edges v g) (const_edges v' g).
  Proof.
    intros v.
    induction v using msetPair_prop.set_induction; intros.
    {
    split.
      { 
        transitivity (vertices g); [|symmetry];
        apply const_edges_empty_vertices.
      }
      {
        unfold const_edges.
        rewrite msetPair_prop.fold_1b; auto.
        rewrite msetPair_prop.fold_1b. reflexivity.
        apply msetPair_prop.empty_is_empty_2.
        transitivity v. symmetry; auto.
        apply msetPair_prop.empty_is_empty_1 in H; auto.
      }
    }
    {
      unfold const_edges.
      apply msetPair_prop.fold_equal.
      {
        apply Equal_equiv.
      }
      {
        constructor; subst.
        transitivity (vertices x1).
        rewrite add_edges_pres_vertices; reflexivity.
        transitivity (vertices y0). apply H3.
        rewrite add_edges_pres_vertices; reflexivity.
        apply gen_Equal_E.
        apply add_edge_morph; auto.
      }
      {
        unfold transpose; intros.
        apply add_edges_transpose.
      }
      exact H1.
    }
  Qed.

  Lemma const_edges_step' : forall v x g,
    msetPair.In x v ->
      Equal (add_edge (const_edges v g) x) (const_edges v g).
  Proof.
    intros v.
    induction v using msetPair_prop.set_induction;
    intros. apply H in H0; inversion H0.
    apply msetPair_prop.Add_Equal in H0.
    transitivity (const_edges (msetPair.add x v1) g).
  Admitted.

  Lemma const_edges_step x v g:
    Equal (add_edge (const_edges v g) x) (const_edges (msetPair.add x v) g).
  Proof.
    unfold const_edges at 2.
    destruct (msetPair_prop.In_dec x v) as [H1 | H1];
    [rewrite msetPair_prop.add_fold with (eqA := Equal)
    |rewrite msetPair_prop.fold_add with (eqA := Equal)];
    try solve
      [ apply Equal_equiv
      | unfold Proper, respectful; intros;
        apply add_edge_morph; auto; simpl
      | unfold transpose; intros; apply add_edges_transpose; simpl
      | auto].
    apply const_edges_step'; auto.
  Qed.
 
  Lemma const_edges_preservation_edges
    v g
    (H0 : forall e, msetPair.In e v -> mset.In (fst e) (vertices g))
    (H1 : forall e, msetPair.In e v -> mset.In (snd e) (vertices g))
    : msetPair.Equal (msetPair.union v (edges g)) (edges (const_edges v g)).
  Proof.
    induction v using msetPair_prop.set_induction.
    {
      rewrite msetPair_prop.empty_union_1; auto.
      unfold const_edges.
      rewrite msetPair_prop.fold_1b; auto.
      reflexivity.
    }
    {
      apply msetPair_prop.Add_Equal in H2.
      generalize H2; intros H3.
      apply msetPair_prop.union_equal_1 with (s'' := (edges g)) in H3.
      transitivity (msetPair.union (msetPair.add x v1) (edges g)); auto.
      transitivity (edges (const_edges (msetPair.add x v1) g));
      [| apply const_edges_eq; symmetry; auto].
      admit.
    }
  Admitted.

  Lemma rebuild_graph_spec :
    forall g, Equal (rebuild_graph g) g.
  Proof.
  (*
    generalize rebuild_graph_spec'.
    intros. constructor; auto.
    specialize (H g).
    induction (edges g) using msetPair_prop.set_induction.
   {
      unfold rebuild_graph, const_edges.
      rewrite msetPair_prop.fold_1b.
      admit.
      apply msetPair_prop.empty_is_empty_1 in H0.
      unfold rebuild_graph, const_edges.
      
      apply msetPair_prop.fold_equal with
        (eqA := Equal)
        (f :=  (fun (elt : msetPair.elt) (subg : t) => add_edge subg elt))
        (i := (const_vertices (vertices g))) in H0.
      destruct H0 as [H0  H1].
      apply (msetPair_prop.equal_trans H1).
      rewrite msetPair_prop.fold_equal with (s' := msetPair.empty).
      admit.
      constructor; auto; unfold Transitive; intros; subst; auto.
      unfold Proper, respectful; intros; subst; auto.
      unfold transpose; intros.
      apply 
eq_equiv.
      SearchAbout Equivalence.
      SearchAbout eq.
      auto.
      Check msetPair_prop.fold_equal.


      apply (msetPair_prop.fold_equal _ (Logic.eq _) .
      symmetry; auto.
    }
    {
      intros. apply msetPair_prop.Add_Equal in H2.
      transitivity (msetPair.add x s').
      split; intros.
      {
        apply msetPair.add_spec.
        destruct (NodePair.eq_dec a0 x); auto.
        right. apply H2.
        apply add_edges_other in H3; auto.
      }
      {
        apply msetPair.add_spec in H3.
        destruct H3 as [H3 | H3].
        subst.
        apply add_edges.
        apply add_edge.
      }
  *)
  Admitted.
  (** An inductive construction for graphs
        wrt. functions avilable to the interface **)
  Inductive constructed_t : t -> Type :=
  | const_empty : constructed_t empty
  | const_vert : forall g x,
      constructed_t g -> constructed_t (add_vertex g x)
  | const_edge : forall g x,
      constructed_t g -> constructed_t (add_edge g x).

  (** A proof that rebuild builds graphs, according to the interfaced
        add/remove functions. **)
  Lemma rebuild_is_constructed : forall g, constructed_t (rebuild_graph g).
  Proof.
    intros g.
    unfold rebuild_graph.
    (* Use set_induction from MSetProperties? *)
  Admitted.
  
  (** The definition of respectful operations **)
  Definition respectful (P : t -> Type) :=
    forall t1 t2, Equal t1 t2 -> P t1 -> P t2.

  (** With all of that out of the way, we can actually prove
        an induction principle **)  
  Lemma ind1 (P : t -> Type) (H0 : respectful P) :
    P empty -> 
    (forall x g, P g -> P (add_vertex g x)) ->
    (forall x g, P g -> P (add_edge g x)) ->
    forall g, P g.
  Proof.
    intros.
    unfold respectful in H0.
    apply H0 with (t1 := rebuild_graph g).
    apply rebuild_graph_spec.
    assert (H3 : constructed_t (rebuild_graph g))
      by apply rebuild_is_constructed.
    induction H3; auto.
  Qed.
  (** We don't know how these graphs are implemented underneath
      the module, and this can make induction principles too
      restricitive. One way to work around this would be
      to require the user to provide their own induction
      principles as axioms to the interface. But, this
      can be burdensome, and may require the introduction
      of axioms like Proof Irrelevance to work around
      (ex. Sam's implementation of graphs for MIS
      and Gordon's instance for list sets).

      But, many of our propositions regarding graphs don't
      care about their underlying construction. Instead,
      we only care about relations between the set of edges
      and the set of vertices. In many (all?) cases, these
      relations should be preserved under the Equal relation
      described above. In this section, we capitalize on this
      fact to construct an induction principle for
      functions/properties which are preserved under this
      Equality relation, tenatively deemed 'respectful'.

      This has a number of benefits:
        1.) Decreased burden of proof for the interface user.
              The user no longer has to generate their own induction
              principles.
        2.) Avoidance of additional axioms such as proof
              irrelevance.
        3.) Technique should be easily extendable.

      The general process for the derivation of the first induction
      principle (ind1) looks like this:
        
        1.) Given an arbitrary graph, rebuild it up to
              Equality using 'rebuild_graph'
        2.) This rebuilt graph is made using the
              only empty, add_vertices and add_edges
              and is thus a memeber of constructed_t.
        3.) We can use the induction/recursion principle of
              constructed_t to destruct the rebuilt graph
              into cases in which the induction hypotheses
              are applicable.
        4.) Since the operation is respectful, we can use this
              output for the rebuilt graph to produce a
              an output for the input graph.
    *)

End Graph.
