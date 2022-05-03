
# Benchmark



## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>Linux</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">AMD Ryzen 5 1600 Six-Core Processor</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">12</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">15.65 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.13.4</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">24.2</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">5 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics




Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">naive_1</td>
    <td style="white-space: nowrap; text-align: right">4.20 K</td>
    <td style="white-space: nowrap; text-align: right">238.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;11.22%</td>
    <td style="white-space: nowrap; text-align: right">231.79 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">333.46 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">naive_2</td>
    <td style="white-space: nowrap; text-align: right">2.77 K</td>
    <td style="white-space: nowrap; text-align: right">361.49 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;9.26%</td>
    <td style="white-space: nowrap; text-align: right">358.48 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">497.22 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">naive_5</td>
    <td style="white-space: nowrap; text-align: right">1.20 K</td>
    <td style="white-space: nowrap; text-align: right">830.08 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;6.73%</td>
    <td style="white-space: nowrap; text-align: right">817.31 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1070.76 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">naive_10</td>
    <td style="white-space: nowrap; text-align: right">0.62 K</td>
    <td style="white-space: nowrap; text-align: right">1602.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;4.38%</td>
    <td style="white-space: nowrap; text-align: right">1591.54 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">1829.25 &micro;s</td>
  </tr>

</table>


Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">naive_1</td>
    <td style="white-space: nowrap;text-align: right">4.20 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">naive_2</td>
    <td style="white-space: nowrap; text-align: right">2.77 K</td>
    <td style="white-space: nowrap; text-align: right">1.52x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">naive_5</td>
    <td style="white-space: nowrap; text-align: right">1.20 K</td>
    <td style="white-space: nowrap; text-align: right">3.48x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">naive_10</td>
    <td style="white-space: nowrap; text-align: right">0.62 K</td>
    <td style="white-space: nowrap; text-align: right">6.73x</td>
  </tr>

</table>



