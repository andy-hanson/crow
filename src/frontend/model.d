module frontend.model;

import util.comparison : compareEnum, compareOr, Comparison;
import util.path : comparePath, PathAndStorageKind;

Comparison comparePathAndStorageKind(immutable PathAndStorageKind a, immutable PathAndStorageKind b) {
	return compareOr(
		compareEnum(a.storageKind, b.storageKind),
		() => comparePath(a.path, b.path));
}
