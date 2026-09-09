"""Version-guarded local backport of ansible/ansible PR #86551.

Remove once a released ansible-core includes the upstream fix.
This changes only Ansible's internal type-hint lookup, not typing globally.
"""
from importlib.metadata import version
from pathlib import Path
import ansible

if version('ansible-core') != '2.21.4':
    raise SystemExit('Cache workaround requires review for this ansible-core version')

root = Path(ansible.__file__).parent / 'module_utils' / '_internal'
validation = root / '_dataclass_validation.py'
tags = root / '_datatag' / '__init__.py'
source = validation.read_text()
tag_source = tags.read_text()
anchor = 'import typing as t\n'
old = 'field_type_hints = t.get_type_hints(cls)'
tag_old = 'type_hints = t.get_type_hints(cls)'
assert source.count(anchor) == 1 and source.count(old) == 1
assert tag_source.count(tag_old) == 1
assert '_cls_type_hints_cache' not in source
helper = '''
from weakref import WeakKeyDictionary

_cls_type_hints_cache: WeakKeyDictionary[type, dict[str, t.Any]] = WeakKeyDictionary()


def get_type_hints(cls: type) -> dict[str, t.Any]:
    try:
        return _cls_type_hints_cache[cls]
    except KeyError:
        hints = t.get_type_hints(cls)
        _cls_type_hints_cache[cls] = hints
        return hints

'''
source = source.replace(anchor, anchor + helper).replace(old, 'field_type_hints = get_type_hints(cls)')
tag_source = tag_source.replace(tag_old, 'type_hints = _dataclass_validation.get_type_hints(cls)')
compile(source, str(validation), 'exec')
compile(tag_source, str(tags), 'exec')
validation.write_text(source)
tags.write_text(tag_source)
print('Applied guarded Ansible cache workaround (upstream PR #86551)')
