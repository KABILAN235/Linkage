class Datapoint {
  final String uuid;
  final String columnId;
  final String recordId;
  final String data;

  Datapoint({
    required this.uuid,
    required this.columnId,
    required this.recordId,
    required this.data,
  });
}

class QueryColumn {
  final String uuid;
  final String name;
  final int sortIdx;

  QueryColumn({required this.uuid, required this.name, required this.sortIdx});
}

class QueryRecord {
  final String uuid;
  final int sortIdx;
  // You might want to include other record-specific fields if necessary

  QueryRecord({required this.uuid, required this.sortIdx});
}
