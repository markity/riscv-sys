#ifndef LIST_H
#define LIST_H

#include "types.h"

// 抄一个内核链表

struct list_node {
    struct list_node *pre;
    struct list_node *next; 
};

static inline void list_node_init(struct list_node *node) {
    node->pre = node->next = (struct list_node*)0;
}

static inline struct list_node* list_node_pre(struct list_node *node) {
    return node->pre;
}

static inline struct list_node* list_node_next(struct list_node *node) {
    return node->next;
}

struct list {
    struct list_node *first;
    struct list_node *last;

    int count;
};

static inline void list_init(struct list *l) {
    l->first = l->last = (struct list_node*)0;
    l->count = 0;
}

static inline int list_is_empty(struct list *l) {
    return l->count == 0;
}

static inline int list_count(struct list *l) {
    return l->count;
}

static inline struct list_node* list_first(struct list *l) {
    return l->first;
}

static inline struct list_node* list_last(struct list *l) {
    return l->last;
}

static inline void list_insert_first(struct list* l, struct list_node *n) {
    n->next = l->first;
    n->pre = (struct list_node *)0;

    if(list_is_empty(l)) {
        l->last = l->first = n;
    } else {
        l->first->pre = n;
        l->first = n;
    }

    l->count ++;
}

static inline void list_insert_last(struct list *l, struct list_node* n) {
    n->pre = l->last;
    n->next = (struct list_node *)0;

    if (list_is_empty(l)) {
        l->first = l->last = n;
    } else {
        l->last->next = n;
        l->last = n;
    }

    l->count++;
}

static inline struct list_node* list_remove_first(struct list*l) {
    if(list_is_empty(l)) {
        return (struct list_node*)0;
    }

    struct list_node *remove_node = l->first;
    l->first = remove_node->next;
    if (l->first == (struct list_node*)0) {
        l->last = (struct list_node*)0;
    } else {
        remove_node->next->pre = (struct list_node*)0;
    }

    remove_node->pre = remove_node->next = (struct list_node*)0;
    l->count --;

    return remove_node;
}

static inline struct list_node* list_remove(struct list* l, struct list_node* n) {
    if (n == l->first) {
        l->first = n->next;
    }

    if (n == l->last) {
        l->last = n->pre;
    }

    if (n->pre) {
        n->pre->next = n->next;
    }

    if (n->next) {
        n->next->pre = n -> pre;
    }

    n->pre = n->next = (struct list_node*)0;
    l->count --;
    return n;
}

#define offset_in_parent(parent_type, node_name) \
    ((uint64)&(((parent_type *)0)->node_name))

#define parent_addr(node, parent_type, node_name) \
    ((uint64)node - offset_in_parent(parent_type, node_name))

#define list_node_parent(node, parent_type, node_name) \
    ((parent_type*) (node ? parent_addr(node, parent_type, node_name) : 0))

#endif