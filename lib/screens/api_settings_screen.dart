import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/home_controller.dart';
import '../models/api_config_model.dart';
import '../services/config_service.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  _ApiSettingsScreenState createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final ConfigService _configService = ConfigService();
  List<ApiConfigModel> _apiConfigs = [];
  String? _activeConfigId;
  bool _isLoading = true;
  // Flag to identify the initial config that can't be deleted
  String? _initialConfigId;

  @override
  void initState() {
    super.initState();
    _loadApiConfigs();
  }

  Future<void> _loadApiConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final configs = await _configService.getAllApiConfigs();
      final activeConfig = await _configService.getActiveApiConfig();

      // The first config loaded is considered the initial one
      final initialConfigId = configs.isNotEmpty ? configs.first.id : null;

      setState(() {
        _apiConfigs = configs;
        _activeConfigId = activeConfig?.id;
        _initialConfigId = initialConfigId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Error loading configurations: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditConfigDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _apiConfigs.isEmpty
              ? _buildEmptyState()
              : _buildConfigList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.api_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No API configurations yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new API configuration to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Configuration'),
            onPressed: () => _showAddEditConfigDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigList() {
    return ListView.builder(
      itemCount: _apiConfigs.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final config = _apiConfigs[index];
        final isActive = config.id == _activeConfigId;
        final isInitialConfig = config.id == _initialConfigId;

        return ApiConfigCard(
          config: config,
          isActive: isActive,
          isInitialConfig: isInitialConfig,
          onSetActive: _setActiveConfig,
          onEdit: () => _showAddEditConfigDialog(
              config: config, isInitialConfig: isInitialConfig),
          onDelete:
              isInitialConfig ? null : () => _showDeleteConfirmation(config),
        );
      },
    );
  }

  Future<void> _setActiveConfig(String configId) async {
    try {
      await _configService.setActiveConfig(configId);
      await _loadApiConfigs();

      // Notify the HomeController that the API config has changed
      if (mounted) {
        context.read<HomeController>().refreshApiConfig();
      }

      _showSuccessSnackBar('API configuration activated');
    } catch (e) {
      _showErrorSnackBar('Error activating configuration: ${e.toString()}');
    }
  }

  Future<void> _showDeleteConfirmation(ApiConfigModel config) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text(
          'Are you sure you want to delete the ${config.providerName} configuration?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _configService.deleteApiConfig(config.id);
        await _loadApiConfigs();

        // Notify the HomeController that the API config might have changed
        if (mounted) {
          context.read<HomeController>().refreshApiConfig();
        }

        _showSuccessSnackBar('API configuration deleted');
      } catch (e) {
        _showErrorSnackBar('Error deleting configuration: ${e.toString()}');
      }
    }
  }

  Future<void> _showAddEditConfigDialog(
      {ApiConfigModel? config, bool isInitialConfig = false}) async {
    final formKey = GlobalKey<FormState>();
    final isEditing = config != null;

    ApiProvider selectedProvider = config?.provider ?? ApiProvider.huggingFace;
    final apiKeyController = TextEditingController(text: config?.apiKey ?? '');
    final modelNameController =
        TextEditingController(text: config?.modelName ?? '');
    final baseUrlController =
        TextEditingController(text: config?.baseUrl ?? '');

    // Set default model name based on provider if creating new config
    if (!isEditing) {
      _setupDefaultValues(
          selectedProvider, modelNameController, baseUrlController);
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              isEditing ? 'Edit API Configuration' : 'Add API Configuration'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider selection (disabled for initial config)
                  DropdownButtonFormField<ApiProvider>(
                    value: selectedProvider,
                    decoration: const InputDecoration(
                      labelText: 'Provider',
                      border: OutlineInputBorder(),
                    ),
                    items: ApiProvider.values.map((provider) {
                      return DropdownMenuItem(
                        value: provider,
                        child: Text(_getProviderName(provider)),
                      );
                    }).toList(),
                    onChanged: isInitialConfig
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() {
                                selectedProvider = value;
                                _setupDefaultValues(value, modelNameController,
                                    baseUrlController);
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),

                  // API Key field
                  TextFormField(
                    controller: apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      border: OutlineInputBorder(),
                      helperText: 'Enter your API key',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an API key';
                      }
                      return null;
                    },
                    obscureText: true,
                    readOnly: isInitialConfig, // Read-only for initial config
                    enabled: !isInitialConfig,
                  ),
                  const SizedBox(height: 16),

                  // Model name field
                  TextFormField(
                    controller: modelNameController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      border: OutlineInputBorder(),
                      helperText: 'Enter model name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a model name';
                      }
                      return null;
                    },
                    readOnly: isInitialConfig, // Read-only for initial config
                    enabled: !isInitialConfig,
                  ),
                  const SizedBox(height: 16),

                  // Base URL field
                  TextFormField(
                    controller: baseUrlController,
                    decoration: InputDecoration(
                      labelText: 'Base URL',
                      border: const OutlineInputBorder(),
                      helperText: selectedProvider == ApiProvider.custom
                          ? 'Required for custom API'
                          : 'Optional (leave as is for default)',
                    ),
                    validator: (value) {
                      if (selectedProvider == ApiProvider.custom &&
                          (value == null || value.isEmpty)) {
                        return 'Base URL is required for custom API';
                      }
                      return null;
                    },
                    readOnly: isInitialConfig, // Read-only for initial config
                    enabled: !isInitialConfig,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (!isInitialConfig) // Only show update/add button for non-initial configs
              FilledButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);

                    final now = DateTime.now();
                    final newConfig = ApiConfigModel(
                      id: isEditing
                          ? config!.id
                          : now.millisecondsSinceEpoch.toString(),
                      provider: selectedProvider,
                      apiKey: apiKeyController.text,
                      modelName: modelNameController.text,
                      baseUrl: baseUrlController.text.isEmpty
                          ? null
                          : baseUrlController.text,
                      isActive: config?.isActive ?? false,
                      createdAt: config?.createdAt ?? now,
                      updatedAt: now,
                    );

                    try {
                      await _configService.saveApiConfig(newConfig);

                      // If this is the first config, set it as active automatically
                      if (_apiConfigs.isEmpty) {
                        await _configService.setActiveConfig(newConfig.id);
                      }

                      // Refresh the list
                      await _loadApiConfigs();

                      // Notify the HomeController
                      if (mounted) {
                        context.read<HomeController>().refreshApiConfig();
                      }

                      _showSuccessSnackBar(
                        isEditing
                            ? 'API configuration updated'
                            : 'API configuration added',
                      );
                    } catch (e) {
                      _showErrorSnackBar('Error: ${e.toString()}');
                    }
                  }
                },
                child: Text(isEditing ? 'Update' : 'Add'),
              ),
            if (isInitialConfig)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to setup default values based on provider
  void _setupDefaultValues(
    ApiProvider provider,
    TextEditingController modelController,
    TextEditingController urlController,
  ) {
    switch (provider) {
      case ApiProvider.huggingFace:
        modelController.text = 'Qwen/Qwen2.5-72B-Instruct';
        urlController.text = 'https://api-inference.huggingface.co/models';
        break;
      case ApiProvider.openAI:
        modelController.text = 'gpt-4o';
        urlController.text = 'https://api.openai.com/v1';
        break;
      case ApiProvider.anthropic:
        modelController.text = 'claude-3-5-sonnet-20240620';
        urlController.text = 'https://api.anthropic.com/v1';
        break;
      case ApiProvider.custom:
        modelController.text = '';
        urlController.text = '';
        break;
    }
  }

  // Helper method to get provider name
  String _getProviderName(ApiProvider provider) {
    switch (provider) {
      case ApiProvider.huggingFace:
        return 'Hugging Face';
      case ApiProvider.openAI:
        return 'OpenAI';
      case ApiProvider.anthropic:
        return 'Anthropic';
      case ApiProvider.custom:
        return 'Custom API';
    }
  }
}

// Reusable widget for API config card
class ApiConfigCard extends StatelessWidget {
  final ApiConfigModel config;
  final bool isActive;
  final bool isInitialConfig;
  final Function(String) onSetActive;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const ApiConfigCard({
    Key? key,
    required this.config,
    required this.isActive,
    required this.isInitialConfig,
    required this.onSetActive,
    required this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isActive ? 2 : 0,
      color: isActive ? colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getProviderIcon(context, config.provider),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            config.providerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (isInitialConfig)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Model: ${config.modelName}',
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text('API Key: ${_maskApiKey(config.apiKey)}',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isActive)
                  TextButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Set Active'),
                    onPressed: () => onSetActive(config.id),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(isInitialConfig ? 'View' : 'Edit'),
                  onPressed: onEdit,
                ),
                if (onDelete != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.error,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getProviderIcon(BuildContext context, ApiProvider provider) {
    IconData iconData;
    Color color;

    switch (provider) {
      case ApiProvider.huggingFace:
        iconData = Icons.psychology_outlined;
        color = Colors.amber;
        break;
      case ApiProvider.openAI:
        iconData = Icons.auto_awesome;
        color = Colors.green;
        break;
      case ApiProvider.anthropic:
        iconData = Icons.smart_toy_outlined;
        color = Colors.purple;
        break;
      case ApiProvider.custom:
        iconData = Icons.settings_ethernet;
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: color,
      ),
    );
  }

  String _maskApiKey(String apiKey) {
    if (apiKey.length <= 8) {
      return '****';
    }
    return apiKey.substring(0, 4) +
        '****' +
        apiKey.substring(apiKey.length - 4);
  }
}
