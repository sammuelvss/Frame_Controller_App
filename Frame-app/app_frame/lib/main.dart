import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() => runApp(const FrameApp());

// ==========================================
// 1. O APLICATIVO PRINCIPAL
// ==========================================
class FrameApp extends StatelessWidget {
  const FrameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle Frame',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF2C3E50),
      ),
      // AQUI ESTÁ O HOME NO LUGAR CERTO!
      home: const TelaInicio(), 
    );
  }
}

// ==========================================
// 2. A SUA NOVA TELA DE INÍCIO
// ==========================================
class TelaInicio extends StatelessWidget {
  const TelaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50), // Fundo escuro (Você pode mudar a cor HEX aqui!)
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone central
            const Icon(Icons.smart_toy, size: 120, color: Color(0xFF27AE60)),
            const SizedBox(height: 20),
            
            // Título do Projeto
            const Text(
              'Projeto FRAME',
              style: TextStyle(
                fontSize: 36, 
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 10),
            
            // Subtítulo
            const Text(
              'Robótica Educacional',
              style: TextStyle(
                fontSize: 18, 
                color: Colors.white70, 
              ),
            ),
            const SizedBox(height: 60),
            
            // Botão para entrar
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                )
              ),
              onPressed: () {
                // Ação de navegar para a tela do controle
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ControleScreen()),
                );
              },
              icon: const Icon(Icons.bluetooth_connected),
              label: const Text(
                'CONECTAR ROBÔ', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. A TELA DO CONTROLE (ESTRUTURA)
// ==========================================
class ControleScreen extends StatefulWidget {
  const ControleScreen({super.key});

  @override
  State<ControleScreen> createState() => _ControleScreenState();
}

// ==========================================
// 4. A TELA DO CONTROLE (LÓGICA E DESIGN)
// ==========================================
class _ControleScreenState extends State<ControleScreen> {
  BluetoothConnection? connection;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;
  bool isConnecting = false;
  bool get isConnected => (connection?.isConnected ?? false);

  String terminalLog = "Aguardando conexão...";

  @override
  void initState() {
    super.initState();
    // Busca dispositivos pareados
    FlutterBluetoothSerial.instance.getBondedDevices().then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        _devicesList = bondedDevices;
      });
    });
  }

  void _conectar() async {
    if (_selectedDevice == null) return;

    setState(() {
      isConnecting = true;
      terminalLog = "Conectando a ${_selectedDevice!.name}...";
    });

    try {
      connection = await BluetoothConnection.toAddress(_selectedDevice!.address);
      setState(() {
        isConnecting = false;
        terminalLog = "Conectado com sucesso!";
      });
    } catch (exception) {
      setState(() {
        isConnecting = false;
        terminalLog = "Erro ao conectar.";
      });
    }
  }

  void _enviarComando(String comando, String nomeComando) async {
    if (isConnected) {
      try {
        connection!.output.add(ascii.encode("$comando\n"));
        await connection!.output.allSent;
        setState(() {
          terminalLog = "Enviado: $nomeComando";
        });
      } catch (e) {
        setState(() {
          terminalLog = "Erro ao enviar.";
        });
      }
    } else {
      setState(() {
        terminalLog = "Robô não está conectado!";
      });
    }
  }

  @override
  void dispose() {
    if (isConnected) {
      connection?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle do Robô'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<BluetoothDevice>(
                    isExpanded: true,
                    hint: const Text(
                      'Selecione o HC-06',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    value: _selectedDevice,
                    items: _devicesList.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text(device.name ?? "Dispositivo Desconhecido"),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDevice = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isConnected || isConnecting ? null : _conectar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, 
                    foregroundColor: Colors.white
                  ),
                  child: Text(isConnecting ? '...' : 'Conectar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isConnected ? "Status: Conectado" : "Status: Desconectado",
              style: TextStyle(color: isConnected ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            SizedBox(
              height: 250,
              width: 250,
              child: GridView.count(
                crossAxisCount: 3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const SizedBox(),
                  _buildDirButton("⬆️", 'F', "Frente", const Color(0xFFFFF9C4), const Color(0xFFF1C40F)),
                  const SizedBox(),
                  _buildDirButton("⬅️", 'L', "Esquerda", const Color(0xFFFFCDD2), const Color(0xFFE74C3C)),
                  _buildDirButton("⬇️", 'B', "Trás", const Color(0xFFBBDEFB), const Color(0xFF3498DB)),
                  _buildDirButton("➡️", 'R', "Direita", const Color(0xFFC8E6C9), const Color(0xFF2ECC71)),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _enviarComando('X', 'LIMPAR FILA'),
                    icon: const Icon(Icons.delete),
                    label: const Text('Limpar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _enviarComando('E', 'EXECUTAR FILA'),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Executar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "> $terminalLog",
                style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirButton(String icone, String cmd, String nome, Color bgColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: InkWell(
        onTap: () => _enviarComando(cmd, nome),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(icone, style: const TextStyle(fontSize: 32)),
          ),
        ),
      ),
    );
  }
}