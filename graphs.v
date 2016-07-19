Set Implicit Arguments.

Require Import ZArith List Bool.

Definition node := positive.

Definition node_eqb := Pos.eqb.

Lemma node_eqb_eq :
  forall x y : node,
    node_eqb x y = true <-> x = y.
Proof.
  intros x y; unfold node_eqb.
  apply Pos.eqb_eq.
Qed.

Lemma node_eqb_refl :
  forall x,
    node_eqb x x = true.
Proof.
  intros x; unfold node_eqb.
  apply Pos.eqb_refl.
Qed.  

Lemma node_eqbP :
  forall x y : node,
    reflect (x = y) (node_eqb x y).
Proof.
  intros.
  destruct (node_eqb x y) eqn:H.
  rewrite node_eqb_eq in H. constructor; auto.
  constructor; intros H2; rewrite H2, node_eqb_refl in H.
  congruence.
Qed.  

(** Undirected Graphs *)

Inductive graph : Type :=
| Empty : graph
| Node :
    node -> (** this node's id *)
    list node -> (** its neighbors *)
    graph -> (** the rest of the graph *)
    graph.

Local Open Scope positive_scope.

Example ex1 : graph :=
  Node 1 (2 :: 3 :: nil)
       (Node 2 (3 :: nil)
             (Node 3 nil Empty)).

Example ex2 : graph :=
  Node 3 (2 :: 1 :: nil)
       (Node 2 (1 :: nil)
             (Node 1 nil Empty)).

(** Return the adjacency list associated by graph g
    with node x. *)

Fixpoint adj_of (x : node) (g : graph) : list node :=
  match g with
  | Empty => nil
  | Node y adj g' =>
    if node_eqb x y then adj
    else adj_of x g'
  end.

(** Return all neighbors in g of node x. *)

Fixpoint nodelist_contains (x : node) (l : list node) : bool :=
  match l with
  | nil => false
  | y :: l' =>
    if node_eqb x y then true
    else nodelist_contains x l'
    (* node_eqb x y || nodelist_contains x l' *)
  end.

Lemma nodelist_containsP :
  forall x l,
    reflect (In x l) (nodelist_contains x l).
Proof.
  induction l; try constructor; auto.
  simpl. destruct (node_eqbP x a).
  constructor; auto.
  destruct (nodelist_contains x l) eqn:H.
  constructor. right. inversion IHl; auto.
  constructor. intros [H2|H2]. subst x. auto. inversion IHl; auto.
Qed.  

Fixpoint neighbors_of (x : node) (g : graph) : list node :=
  match g with
  | Empty => nil
  | Node y adj g' =>
    if node_eqb x y then adj ++ neighbors_of x g'
    else if nodelist_contains x adj then y :: neighbors_of x g'
         else neighbors_of x g'
  end.

Fixpoint graph_contains (x : node) (g : graph) : bool :=
  match g with
  | Empty => false
  | Node y adj g' =>
    if node_eqb x y then true
    else graph_contains x g'
  end.

Inductive graph_ok : graph -> Prop :=
| EmptyOk : graph_ok Empty
| NodeOk :
    forall (x : node) (adj : list node) (g : graph),
      graph_contains x g = false ->
      forallb (fun y => graph_contains y g) adj = true -> (** No self-loops! *)
      graph_ok g ->
      graph_ok (Node x adj g).

(** A so-called "smart constructor" for "Node". 
    We enforce the following two properties: 
      1) "x" is not already in the graph; 
      2) every node in "adj" is in the graph. *)

Definition add_node (x : node) (adj : list node) (g : graph) : graph :=
  if negb (graph_contains x g) && forallb (fun y => graph_contains y g) adj
  then Node x adj g
  else g.

Lemma add_node_ok :
  forall x adj g,
    graph_ok g ->
    graph_ok (add_node x adj g).
Proof.
  intros x adj g H.
  unfold add_node.
  destruct (negb (graph_contains x g) &&
            forallb (fun y : node => graph_contains y g) adj) eqn:H2.
  symmetry in H2; apply andb_true_eq in H2; destruct H2.
  apply NodeOk.
  { symmetry in H0; rewrite negb_true_iff in H0; apply H0. }
  { rewrite <-H1; auto. }
  apply H.
  apply H.
Qed.    

Lemma ex1_graph_ok : graph_ok ex1.
Proof.
  unfold ex1; repeat (constructor; auto).
  (*apply NodeOk; auto.
  apply NodeOk; auto.
  apply NodeOk; auto.
  apply EmptyOk.*)
Qed.  

Lemma filter_property :
  forall (A : Type) (l : list A) (f : A -> bool),
    forallb f (filter f l) = true.
Proof.
  induction l.
  { simpl. auto. }
  simpl. intros f. destruct (f a) eqn:H.
  { simpl. rewrite H. simpl. apply IHl. }
  apply IHl.
Qed.  

Definition remove (x : node) (adj : list node) : list node :=
  filter (fun z => negb (node_eqb x z)) adj.

Lemma remove_app :
  forall x l1 l2,
    remove x (l1 ++ l2) = remove x l1 ++ remove x l2.
Proof.
  unfold remove.
  intros x l1 l2.
  induction l1; auto.
  simpl.
  destruct (negb _); auto.
  simpl. f_equal. auto.
Qed.  

Lemma In_remove_weaken :
  forall x y l,
    In y (remove x l) -> In y l.
Proof.
  induction l; auto.
  simpl. destruct (negb _).
  { inversion 1; subst.
    left; auto.
    right; auto. }
  intros H; right; apply IHl; auto.
Qed.    

Lemma In_remove_neq :
  forall x y l,
    In y (remove x l) -> x <> y.
Proof.
  intros x y.
  induction l; auto.
  simpl. destruct (negb _) eqn:H.
  { assert (H2: x <> a).
    { intros H2. rewrite H2, node_eqb_refl in H; simpl in H; congruence. }
    inversion 1; subst; auto. }
  auto.
Qed.    

Lemma not_In_remove_eq :
  forall x y l,
    In y l -> ~In y (remove x l) -> x = y.
Proof.
  intros x y.
  induction l; auto.
  { simpl. congruence. }
  simpl. intros [H|H].
  { subst y. intros H.
    destruct (negb _) eqn:H2.
    rewrite not_in_cons in H. destruct H. exfalso; apply H; auto.
    destruct (node_eqbP x a); auto. simpl in H2. congruence. }
  destruct (node_eqbP x a); auto.
  unfold negb. rewrite not_in_cons. intros [H1 H2]. auto.
Qed.  

Fixpoint remove_node (x : node) (g : graph) : graph :=
  match g with
  | Empty => Empty
  | Node y adj g' =>
    if node_eqb x y then remove_node x g'
    else Node y (remove x adj) (remove_node x g')
  end.

Lemma remove_node_neighbors_of :
  forall x y g,
    x <> y -> 
    neighbors_of y (remove_node x g) = remove x (neighbors_of y g).
Proof.
  intros x y g H; induction g; auto.
  simpl.
  destruct (node_eqb x n) eqn:H2.
  { rewrite node_eqb_eq in H2; subst n.
    destruct (node_eqb y x) eqn:H3.
    { rewrite node_eqb_eq in H3; subst y.
      exfalso; apply H; auto. }
    rewrite IHg.
    destruct (nodelist_contains _ _); auto.
    simpl. rewrite node_eqb_refl. auto. }
  destruct (node_eqb y n) eqn:H3.
  { simpl; rewrite H3; auto.
    rewrite IHg, remove_app; auto. }
  simpl. rewrite H3.
  destruct (nodelist_containsP y (remove x l)).
  { destruct (nodelist_containsP y l).
    simpl. rewrite H2. simpl. rewrite IHg. auto.
    destruct (nodelist_containsP y l). congruence.
    destruct (nodelist_containsP y (remove x l)); [|congruence].
    apply In_remove_weaken in i; contradiction. }
  destruct (nodelist_containsP y l); auto.
  simpl. rewrite H2. simpl. rewrite IHg.
  exfalso. apply H. apply not_In_remove_eq in n0; auto.
Qed.    

Lemma remove_node_contains :
  forall x y g,
    x <> y -> 
    graph_contains y (remove_node x g) = graph_contains y g.
Proof.
  intros x y g H; induction g; auto.
  simpl.
  destruct (node_eqb x n) eqn:H2.
  { rewrite node_eqb_eq in H2; subst n.
    destruct (node_eqb y x) eqn:H2.
    { rewrite node_eqb_eq in H2; subst y.
      exfalso; apply H; auto. }
    auto. }
  destruct (node_eqb y n) eqn:H3.
  rewrite node_eqb_eq in H3; subst n.
  simpl. rewrite node_eqb_refl; auto.
  simpl. rewrite H3. auto.
Qed.  

Lemma remove_node_ok :
  forall x g,
    graph_ok g ->
    graph_ok (remove_node x g).
Proof.
  intros x g H.
  induction g.
  { simpl; auto. }
  simpl.
  destruct (node_eqb x n) eqn:H2.
  { rewrite node_eqb_eq in H2.
    subst n.
    inversion H; subst; auto. }
  apply NodeOk.
  { inversion H; subst.
    rewrite remove_node_contains; auto.
    intros H3; subst x. rewrite node_eqb_refl in H2. congruence. }
  { inversion H; subst.
    specialize (IHg H6). clear H6.
    rewrite forallb_forall.
    intros y H6.
    rewrite forallb_forall in H5.
    rewrite remove_node_contains.
    { apply H5.
      apply In_remove_weaken in H6; auto. }
    apply In_remove_neq in H6; auto. }
  inversion H; subst.
  auto.
Qed.      

(** Other potential operators/predicates/definitions: 
    - definition of paths from x <-> y
    - does such a path exist between x <-> y? 
    - graph union 
    - set of vertices 
    - set of edges 
    - induced graph for a given set of vertices 
    - graph isomorphism (predicate over a labeling from 
      one graph to the other)
    - definitions of independent sets, maximal independent sets, etc. 

    Other possible projects: 
    - Is there a graph invariant that implies: 
      "graph isomorphism implies syntactic equality"?
    - Abstract interface over "inductive graphs", together with 
      associated induction principle, plus faster implementation
 *)