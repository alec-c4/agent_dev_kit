---
name: django-patterns
description: Django patterns — models, views, ORM optimization. Load after stacks/django profile.
user-invokable: false
---

# Django patterns

Load after [stacks/django](../stacks/django/SKILL.md).

## Structure

- Fat models / thin views **or** service layer — match project; avoid 300-line views.
- **Class-based views** or DRF viewsets per project standard.
- **Migrations** for schema; never hand-edit production DB.

## ORM

- `select_related` / `prefetch_related` for N+1 ([profile dod_overlay](../stacks/django/profile.yaml) `orm_optimization`).
- Use `F()` expressions and `bulk_*` for batch updates.

## Testing

- `pytest-django` or `manage.py test` per project; factories preferred.

## References

- [Django docs](https://docs.djangoproject.com/)
