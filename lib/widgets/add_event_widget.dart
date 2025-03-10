import 'package:flutter/material.dart';
import 'package:second_brain_app/models/item_model.dart';
import 'package:second_brain_app/widgets/delete_confirmation_dialog.dart';

class AddEventWidget extends StatefulWidget {
  final EventModel? eventNote;

  const AddEventWidget({
    Key? key,
    this.eventNote,
  }) : super(key: key);

  @override
  State<AddEventWidget> createState() => _AddEventWidgetState();
}

class _AddEventWidgetState extends State<AddEventWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _titleError = false;
  bool _dateError = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventNote != null) {
      _titleController.text = widget.eventNote!.title;
      _descriptionController.text = widget.eventNote!.description;
      _selectedDate = widget.eventNote?.eventDateTime ?? DateTime.now();
      _selectedTime = TimeOfDay.fromDateTime(widget.eventNote!.eventDateTime);

      // Format and set the date and time text fields
      _dateController.text = _selectedDate?.toString().split(' ')[0] ?? '';
      _timeController.text = _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
          : '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.eventNote != null ? 'Edit Event' : 'Add New Event',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.eventNote != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeleteConfirmationDialog(
                        title: 'Delete Event',
                        message: 'Are you sure you want to delete this event?',
                        onDelete: () {
                          Navigator.pop(context, {
                            'delete': true,
                            'id': widget.eventNote?.id,
                          });
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Event Title',
              hintText: 'Enter event title',
              errorText: _titleError ? 'Title is required' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _titleError
                      ? Theme.of(context).colorScheme.error
                      : Colors.grey,
                ),
              ),
              prefixIcon: Icon(
                Icons.event_note,
                color: _titleError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            onChanged: (value) {
              if (_titleError) {
                setState(() => _titleError = false);
              }
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: 'Select date',
                    errorText: _dateError ? 'Date is required' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _dateError
                            ? Theme.of(context).colorScheme.error
                            : Colors.grey,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.calendar_today,
                      color: _dateError
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365 * 100)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 100)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _dateController.text = picked.toString().split(' ')[0];
                        _dateError = false;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    hintText: 'Select time',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    prefixIcon: Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedTime = picked;
                        _timeController.text = picked.format(context);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Enter event description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(
                Icons.description,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _titleError = _titleController.text.trim().isEmpty;
                    _dateError = _selectedDate == null;
                  });

                  if (!_titleError && !_dateError) {
                    final DateTime eventDateTime = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime?.hour ?? 0,
                      _selectedTime?.minute ?? 0,
                    );
                    Navigator.pop(context, {
                      'id': widget.eventNote?.id,
                      'title': _titleController.text,
                      'description': _descriptionController.text,
                      'datetime': eventDateTime.toIso8601String(),
                    });
                  }
                },
                child: Text(widget.eventNote != null ? 'Update' : 'Add Event'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
