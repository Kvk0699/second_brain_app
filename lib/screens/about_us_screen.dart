import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  final String _aboutUsContent = """
## Who We Are

We are two engineers with expertise in Generative AI and Flutter UI development who understand the importance of data privacy and security in today's digital world. Born from our own concerns about cloud-based storage systems that automatically sync and store personal data with tech giants, Second Brain was created as an alternative that puts you in control of your information.

## Our Mission

Second Brain aims to provide a secure, private, and intelligent solution for managing your sensitive information entirely on your device. We believe your personal data should remain personal – accessible to you whenever needed, but never exposed to unnecessary risks.

## Why Second Brain?

Unlike mainstream cloud services, Second Brain stores everything locally on your device. Your notes, passwords, events, and documents never leave your phone unless you explicitly choose to export them. Our AI-powered search helps you find what you need quickly without compromising on security.

## Open Source

Second Brain is an open source project. We believe in transparency and community collaboration. Anyone can view our code and help make Second Brain better!

Visit our [GitHub repository](https://github.com/Kvk0699/second_brain_app) to see our code, report issues, or suggest improvements.

## Get in Touch

Have questions or feedback about Second Brain? We'd love to hear from you!

* Email: contact@secondbrain.app

## How You Can Help

We welcome contributions of all kinds:

* *Share feedback* about your experience
* *Report any issues* you encounter
* *Suggest new features* you'd like to see
* *Spread the word* if you find the app useful

## Coming Soon

We're constantly working to improve Second Brain. Future updates may include:

* Private cloud backup options
* Advanced data organization
* Enhanced AI capabilities
* Cross-device synchronization
* Desktop applications

## Our Commitment

We're committed to continuous improvement of Second Brain while maintaining our core principles of privacy and security. This initial version allows you to securely store your information and retrieve it through natural language queries, with more features planned for future updates.

Join us in building the future of personal data management!

---

# Terms and Conditions

## 1. Data Privacy

Second Brain stores all user data locally on your device. We do not collect, store, or have access to any information you input into the app. All processing of your data occurs entirely on your device.

## 2. User Responsibilities

You are responsible for:
* Maintaining the security of your device
* Creating regular backups of your data
* Safeguarding access to your device and the app
* The accuracy and legality of the information you store

## 3. Limitations

The app is provided "as is" without warranties of any kind. We are not liable for any damages or losses resulting from:
* Loss of data due to device failure
* Unauthorized access to your device
* Bugs or technical issues with the app
* Incorrect information retrieval by the AI component

## 4. Open Source License

Second Brain is available under [open source license]. You may view, fork, and modify the code according to the terms of this license.

## 5. Updates

We reserve the right to:
* Update the app to improve functionality
* Modify these Terms and Conditions at any time
* Discontinue the app or certain features with reasonable notice

## 6. Governing Law

These Terms and Conditions shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions.

Last updated: March 15, 2025""";

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us & Contribute',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      body: Markdown(
        data: _aboutUsContent,
        selectable: true,
        onTapLink: (text, href, title) {
          if (href != null) {
            _launchUrl(href);
          }
        },
        styleSheet: MarkdownStyleSheet(
          h1: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
          h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
          p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
          listBullet: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
          a: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
        ),
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}
