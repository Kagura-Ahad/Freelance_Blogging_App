import 'dart:io';
import 'dart:convert'; // For jsonDecode if needed for errors
import 'package:http/http.dart' as http; // Use the standard http package
import '../models/message.dart'; // Ensure this path is correct

class SocialService {
  // --- Discord Webhook Configuration ---
  static const String _discordWebhookUrl = 'https://discord.com/api/webhooks/1367610788629581965/1qFTVy-F68xywRICnVEq0jTXbDfptrxShOo5C8eTUqu-qmK02f4M0HIBNFRwURUIvoja';

  // --- Check if Configured ---
  bool isConfigured() {
    return _discordWebhookUrl.isNotEmpty &&
        !_discordWebhookUrl.contains('YOUR_DISCORD_WEBHOOK_URL');
  }

  // --- Main Upload Method (Returns bool) ---
  Future<bool> uploadMessage(Message message) async {
    if (!isConfigured()) {
      print('Discord service is not configured. Check Webhook URL.');
      return false;
    }
    try {
      if (message.imagePath == null || message.imagePath!.isEmpty) {
        print('Error: No image path provided for Discord upload.');
        return false;
      }
      final imageFile = File(message.imagePath!);
      if (!await imageFile.exists()) {
        print('Error: Image file does not exist at path: ${message.imagePath}');
        return false;
      }
      print('Attempting to upload to Discord using http package: ${message.imagePath}');
      return await _uploadToDiscordWebhook(
        imageFile,
        title: message.title,
        description: message.content,
      );
    } catch (e, stackTrace) {
      print('Error in uploadMessage (Discord/http): $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // --- Internal Method for Discord Upload Logic using HTTP Package ---
  Future<bool> _uploadToDiscordWebhook(
      File imageFile, {
        String? title,
        String? description,
      }) async {
    try {
      // 1. Format Discord message content (Markdown)
      String discordContent = _formatDiscordContent(title, description);
      print('Formatted Discord content: $discordContent');

      // 2. Create Multipart Request using http package
      final uri = Uri.parse(_discordWebhookUrl);
      var request = http.MultipartRequest('POST', uri);

      // 3. Add text fields
      request.fields['content'] = discordContent;
      
      // 4. Add the file field
      final fileName = imageFile.path.split('/').last;
      print('Preparing http.MultipartRequest with file: $fileName');
      request.files.add(
          await http.MultipartFile.fromPath(
            'file', // Field name expected by Discord
            imageFile.path,
            filename: fileName,
          )
      );

      // 5. Send the request
      print('Sending request to Discord Webhook via http package...');
      // Send the request and get the streamed response
      final streamedResponse = await request.send();

      // 6. Read the response from the stream
      final response = await http.Response.fromStream(streamedResponse);

      // --- Process Response ---
      print('--- Discord Webhook Response (http) ---');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('------------------------------------');

      // Check for success status codes (200 OK or 204 No Content are common)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('Successfully posted to Discord channel via Webhook (http)!');
        return true; // Indicate success
      } else {
        // Handle error status codes
        print('Failed to post to Discord (http). Status: ${response.statusCode}');
        return false; // Indicate failure
      }

    }
    // Catch specific network-related errors if helpful
    on SocketException catch (e, stackTrace) {
      print('SocketException posting to Discord (http): $e');
      print('Check network connection.');
      print('Stack trace: $stackTrace');
      return false;
    }
    // Catch other potential http client errors
    on http.ClientException catch (e, stackTrace) {
      print('ClientException posting to Discord (http): $e');
      print('Stack trace: $stackTrace');
      return false;
    }
    // Catch any other generic errors
    catch (e, stackTrace) {
      print('Generic Exception posting to Discord (http): $e');
      print('Stack trace: $stackTrace');
      return false; // Indicate failure
    }
  }

  // --- Helper to Format Discord Content (Markdown) ---
  String _formatDiscordContent(String? title, String? description) {
    String content = "";
    if (title != null && title.isNotEmpty) {
      content += "**${title.trim()}**\n\n";
    }
    if (description != null && description.isNotEmpty) {
      content += description.trim();
    }
    if (content.trim().isEmpty) {
      content = "(Uploaded via Flutter app)";
    }
    return content.trim();
  }


  // --- Compatibility Methods while integrating updated code
  Future<bool> isAuthenticated() async {
    return isConfigured();
  }
  Future<bool> uploadMessageBool(Message message) async {
    return await uploadMessage(message);
  }
  Future<bool> uploadMessageOld(Message message) async {
    return await uploadMessageBool(message);
  }
  Future<String?> getConnectedPlatform() async {
    return isConfigured() ? 'discord' : null;
  }
}