import 'package:flutter/material.dart';
import 'package:linkage/screens/table_screen/types.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Placeholder data models - replace with your actual models

class TableScreen extends StatefulWidget {
  final String queryUuid; // Pass the query_uuid to this screen

  const TableScreen({super.key, required this.queryUuid});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late Future<Map<String, dynamic>> _tableDataFuture;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tableDataFuture = _fetchTableData();
  }

  // Placeholder for your actual data fetching logic
  Future<Map<String, dynamic>> _fetchTableData() async {
    try {
      // 1. Fetch Columns for the queryUuid
      final columnsResponse = await supabase
          .from('Column')
          .select('uuid, name, sort_idx')
          .eq('query_uuid', widget.queryUuid)
          .order('sort_idx', ascending: true);

      // if (columnsResponse.error != null) { // Supabase < 2.0 error handling
      //   throw Exception('Failed to load columns: ${columnsResponse.error!.message}');
      // }
      // For Supabase >= 2.0, errors are thrown directly or check for null data.
      // The .select() itself will throw if there's az PostgREST error and no data.
      // However, it's good practice to check if the data is what you expect.

      final List<QueryColumn> columns =
          (columnsResponse as List<dynamic>)
              .map(
                (data) => QueryColumn(
                  uuid: data['uuid'] as String,
                  name: data['name'] as String,
                  sortIdx: data['sort_idx'] as int,
                ),
              )
              .toList();

      if (columns.isEmpty) {
        // Handle case where no columns are found, perhaps return early or throw specific error
        return {'columns': <QueryColumn>[], 'rows': <Map<String, String>>[]};
      }

      // 2. Fetch Records for the queryUuid
      final recordsResponse = await supabase
          .from('Record')
          .select('uuid, sort_idx')
          .eq('query_uuid', widget.queryUuid)
          .order('sort_idx', ascending: true);

      final List<QueryRecord> records =
          (recordsResponse as List<dynamic>)
              .map(
                (data) => QueryRecord(
                  uuid: data['uuid'] as String,
                  sortIdx: data['sort_idx'] as int,
                ),
              )
              .toList();

      if (records.isEmpty) {
        // Handle case where no records are found
        return {'columns': columns, 'rows': <Map<String, String>>[]};
      }

      // 3. Fetch Datapoints for the fetched records
      final List<String> recordUuids = records.map((r) => r.uuid).toList();
      final datapointsResponse = await supabase
          .from('Datapoint')
          .select('uuid, column_id, record_id, data')
          .inFilter('record_id', recordUuids);

      final List<Datapoint> allDatapoints =
          (datapointsResponse as List<dynamic>)
              .map(
                (data) => Datapoint(
                  uuid: data['uuid'] as String,
                  columnId: data['column_id'] as String,
                  recordId: data['record_id'] as String,
                  data: data['data'] as String,
                ),
              )
              .toList();

      // Structure data for the DataTable
      List<Map<String, String>> processedRows = [];
      for (var record in records) {
        Map<String, String> rowData = {};
        for (var datapoint in allDatapoints.where(
          (dp) => dp.recordId == record.uuid,
        )) {
          rowData[datapoint.columnId] = datapoint.data;
        }
        processedRows.add(rowData);
      }

      return {'columns': columns, 'rows': processedRows};
    } catch (e) {
      // Log the error or handle it more gracefully in the UI
      print('Error fetching table data: $e');
      throw Exception('Failed to load table data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Query Results')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _tableDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data found.'));
          }

          final List<QueryColumn> columns = snapshot.data!['columns'];
          final List<Map<String, String>> rowsData = snapshot.data!['rows'];

          if (columns.isEmpty) {
            return const Center(
              child: Text('No columns defined for this query.'),
            );
          }

          return SizedBox.expand(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns:
                        columns
                            .map(
                              (column) => DataColumn(label: Text(column.name)),
                            )
                            .toList(),
                    rows:
                        rowsData
                            .map(
                              (rowDataMap) => DataRow(
                                cells:
                                    columns
                                        .map(
                                          (column) => DataCell(
                                            Text(rowDataMap[column.uuid] ?? ''),
                                          ),
                                        )
                                        .toList(),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
